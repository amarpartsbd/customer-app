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

  /// Cart: productId -> {'product': {...}, 'qty': num} (decimals for items sold by weight, e.g. 1.5 kg)
  final Map<int, Map<String, dynamic>> _cart = {};

  String? token;
  Map<String, dynamic>? customer;

  bool get isLoggedIn => token != null && customer != null;

  Color get brandColor {
    if (isNf) return const Color(0xFF14532D); // the website's green
    final hex = config['primary_color']?.toString();
    if (hex != null && hex.startsWith('#') && hex.length == 7) {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
    return const Color(0xFF16A34A); // grocery green default
  }

  String get currency => (config['currency'] ?? '৳').toString();

  /// Store design from the API: 'nogorfarm' switches the app to the Nogor Farm look.
  String? get skin => config['skin']?.toString();
  bool get isNf => skin == 'nogorfarm';

  /// Money in the store's style (Bangla digits for the Nogor Farm look).
  String fmt(num v) => isNf ? _bnMoney(currency, v) : '$currency${_group(v)}';
  static String _group(num v) {
    final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    final parts = s.split('.');
    final d = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$d${parts.length > 1 ? '.${parts[1]}' : ''}';
  }
  static String _bnMoney(String cur, num v) {
    const bn = {'0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪', '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'};
    final s = v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return cur + s.replaceAllMapped(RegExp(r'[0-9]'), (m) => bn[m[0]]!);
  }

  /* ─────────── selling rules (same as the server's Product::priceFor) ─────────── */

  static double stepOf(Map<String, dynamic> p) => ((p['step'] ?? 1) as num).toDouble();
  static double minOf(Map<String, dynamic> p) => ((p['min'] ?? 1) as num).toDouble();
  static double defaultQtyOf(Map<String, dynamic> p) => ((p['default_qty'] ?? p['min'] ?? 1) as num).toDouble();

  /// Price for a quantity: the admin's option price when the quantity is an option
  /// (e.g. 2 kg pack), otherwise unit price × quantity.
  static double priceFor(Map<String, dynamic> p, num qty) {
    for (final o in (p['options'] as List? ?? const [])) {
      if (o is Map && ((o['qty'] as num) - qty).abs() < 0.0005) return (o['price'] as num).toDouble();
    }
    return ((p['price'] ?? 0) as num).toDouble() * qty;
  }

  /// Compare-at (old) price for a quantity, or 0.
  static double compareFor(Map<String, dynamic> p, num qty) {
    final rate = ((p['compare_price'] ?? 0) as num).toDouble();
    final cmp = rate * qty;
    return cmp > priceFor(p, qty) ? cmp : 0;
  }
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
  /// Badge count: number of products in the cart (quantities can be weights like 1.5 kg).
  int get cartCount => _cart.length;
  bool get cartEmpty => _cart.isEmpty;

  double get cartSubtotal => _cart.values.fold(0.0, (s, l) => s + lineTotal(l));

  double lineTotal(Map<String, dynamic> l) => priceFor(Map<String, dynamic>.from(l['product']), l['qty'] as num);

  double get deliveryCharge {
    final over = (config['free_delivery_over'] as num?)?.toDouble() ?? 0;
    if (over > 0 && cartSubtotal >= over) return 0;
    return (config['delivery_charge'] as num?)?.toDouble() ?? 0;
  }

  double get cartTotal => cartSubtotal + deliveryCharge;

  num qtyOf(int productId) => _cart[productId]?['qty'] as num? ?? 0;

  /// Adds [qty] (default: the product's default amount, e.g. 1 kg). Weight items keep decimals.
  void addToCart(Map<String, dynamic> product, [num? qty]) {
    final id = product['id'] as int;
    final cur = _cart[id]?['qty'] as num? ?? 0;
    _cart[id] = {'product': product, 'qty': _norm(product, cur + (qty ?? defaultQtyOf(product)))};
    _saveCart();
    notifyListeners();
  }

  /// Sets the line's quantity; below the product's minimum removes it.
  void setQty(int productId, num qty) {
    final line = _cart[productId];
    if (line == null) return;
    final p = Map<String, dynamic>.from(line['product']);
    if (qty < minOf(p) - 0.0005) {
      _cart.remove(productId);
    } else {
      line['qty'] = _norm(p, qty);
    }
    _saveCart();
    notifyListeners();
  }

  /// Whole units for items not sold by weight; weights rounded to grams, capped at 999.
  static num _norm(Map<String, dynamic> p, num q) {
    final v = p['sold_by_weight'] == true ? (q * 1000).round() / 1000 : q.round();
    return v.clamp(minOf(p), 999);
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
