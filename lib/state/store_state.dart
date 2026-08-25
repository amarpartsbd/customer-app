import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';

enum LoadStatus { loading, ready, error }

/// Central store state: branding config, local cart, customer session.
class StoreState extends ChangeNotifier {
  final ApiClient api = ApiClient();
  final _storage = const FlutterSecureStorage();

  LoadStatus status = LoadStatus.loading;
  String? loadError;

  /// Branding + settings from /store/config.
  Map<String, dynamic> config = {};

  /// Cart: productId -> {'product': {...}, 'qty': int}
  final Map<int, Map<String, dynamic>> _cart = {};

  String? token;
  Map<String, dynamic>? customer;

  bool get isLoggedIn => token != null && customer != null;

  Color get brandColor {
    final hex = config['primary_color']?.toString();
    if (hex != null && hex.startsWith('#') && hex.length == 7) {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
    return const Color(0xFF16A34A); // grocery green default
  }

  String get currency => (config['currency'] ?? '৳').toString();
  String get storeName {
    final app = config['app'];
    if (app is Map && (app['name']?.toString().isNotEmpty ?? false)) return app['name'].toString();
    return (config['name'] ?? 'Online Store').toString();
  }

  /* ─────────── bootstrap ─────────── */

  Future<void> bootstrap() async {
    await _loadCart();
    token = await _storage.read(key: 'token');
    if (token != null) api.setToken(token);
    try {
      config = Map<String, dynamic>.from(await api.get('/config'));
      if (token != null) {
        try {
          final me = await api.get('/me');
          customer = Map<String, dynamic>.from(me['customer']);
        } catch (_) {
          await logout(silent: true);
        }
      }
      status = LoadStatus.ready;
    } catch (e) {
      loadError = e.toString();
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  /* ─────────── cart ─────────── */

  List<Map<String, dynamic>> get cartLines => _cart.values.toList();
  int get cartCount => _cart.values.fold(0, (s, l) => s + (l['qty'] as int));
  bool get cartEmpty => _cart.isEmpty;

  double get cartSubtotal => _cart.values.fold(0.0, (s, l) {
        final price = ((l['product']['price'] ?? 0) as num).toDouble();
        return s + price * (l['qty'] as int);
      });

  double get deliveryCharge {
    final over = (config['free_delivery_over'] as num?)?.toDouble() ?? 0;
    if (over > 0 && cartSubtotal >= over) return 0;
    return (config['delivery_charge'] as num?)?.toDouble() ?? 0;
  }

  double get cartTotal => cartSubtotal + deliveryCharge;

  int qtyOf(int productId) => _cart[productId]?['qty'] as int? ?? 0;

  void addToCart(Map<String, dynamic> product, [int qty = 1]) {
    final id = product['id'] as int;
    final cur = _cart[id]?['qty'] as int? ?? 0;
    _cart[id] = {'product': product, 'qty': (cur + qty).clamp(1, 999)};
    _saveCart();
    notifyListeners();
  }

  void setQty(int productId, int qty) {
    if (qty <= 0) {
      _cart.remove(productId);
    } else if (_cart.containsKey(productId)) {
      _cart[productId]!['qty'] = qty.clamp(1, 999);
    }
    _saveCart();
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.remove(productId);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    await _storage.write(key: 'cart', value: jsonEncode(_cart.map((k, v) => MapEntry(k.toString(), v))));
  }

  Future<void> _loadCart() async {
    final raw = await _storage.read(key: 'cart');
    if (raw == null) return;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw));
      _cart.clear();
      map.forEach((k, v) => _cart[int.parse(k)] = Map<String, dynamic>.from(v));
    } catch (_) {}
  }

  /* ─────────── auth ─────────── */

  Future<void> login(String login, String password) async {
    final res = await api.post('/login', body: {'login': login, 'password': password});
    await _saveSession(res);
  }

  Future<void> register(String name, String phone, String? email, String password) async {
    final res = await api.post('/register', body: {'name': name, 'phone': phone, 'email': email, 'password': password});
    await _saveSession(res);
  }

  Future<void> _saveSession(dynamic res) async {
    token = res['token'];
    await _storage.write(key: 'token', value: token);
    api.setToken(token);
    customer = Map<String, dynamic>.from(res['customer']);
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    final res = await api.post('/profile', body: body);
    customer = Map<String, dynamic>.from(res['customer']);
    notifyListeners();
  }

  Future<void> logout({bool silent = false}) async {
    if (!silent) {
      try {
        await api.post('/logout');
      } catch (_) {}
    }
    await _storage.delete(key: 'token');
    token = null;
    customer = null;
    api.setToken(null);
    notifyListeners();
  }

  /* ─────────── checkout ─────────── */

  /// Places the order. Returns the response (order_number, or payment_url).
  Future<Map<String, dynamic>> checkout({
    required String name,
    required String phone,
    required String address,
    String? city,
    String? notes,
    String paymentMethod = 'cod',
  }) async {
    final items = _cart.values.map((l) => {'product_id': l['product']['id'], 'qty': l['qty']}).toList();
    final res = await api.post('/checkout', body: {
      'items': items,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'notes': notes,
      'payment_method': paymentMethod,
    });
    return Map<String, dynamic>.from(res);
  }
}
