import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';
import '../widgets/product_card.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.productId});
  final int productId;
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Map<String, dynamic>? _p;
  List<Map<String, dynamic>> _related = [];
  bool _loading = true;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await context.read<StoreState>().api.get('/products/${widget.productId}');
      _p = Map<String, dynamic>.from(d['data']);
      _related = (d['related'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final brand = state.brandColor;
    final cur = state.currency;
    final p = _p;
    final off = ((p?['discount_percent'] ?? 0) as int);

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (p == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('পণ্য পাওয়া যায়নি।', style: TextStyle(color: kMuted))));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _bottomBar(context, state, p, cur, brand),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: _circle(Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: brandTint(brand, 0.06),
              padding: const EdgeInsets.fromLTRB(28, 70, 28, 28),
              child: Stack(children: [
                Center(child: p['image'] != null
                    ? Image.network(p['image'], fit: BoxFit.contain, errorBuilder: (_, _, _) => const Text('🛍️', style: TextStyle(fontSize: 90)))
                    : const Text('🛍️', style: TextStyle(fontSize: 90))),
                if (off > 0)
                  Positioned(right: 0, top: 0, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(20)),
                    child: Text('-$off%', style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                  )),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -22),
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ((p['category'] ?? '').toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: brandTint(brand, 0.10), borderRadius: BorderRadius.circular(20)),
                    child: Text(p['category'].toString(), style: TextStyle(color: Color.lerp(brand, Colors.black, 0.15), fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 12),
                Text(p['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kInk, height: 1.22)),
                if ((p['unit'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(p['unit'], style: const TextStyle(fontSize: 13, color: kFaint)),
                ],
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(money(cur, (p['price'] ?? 0) as num), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: brand, height: 1)),
                  if (off > 0) ...[
                    const SizedBox(width: 10),
                    Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(money(cur, (p['compare_price'] ?? 0) as num), style: const TextStyle(fontSize: 15, color: kFaint, decoration: TextDecoration.lineThrough))),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: kSuccess),
                      SizedBox(width: 4),
                      Text('স্টকে আছে', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kSuccess)),
                    ]),
                  ),
                ]),
                if ((p['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('বিবরণ', style: TextStyle(fontWeight: FontWeight.w800, color: kInk, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(p['description'], style: const TextStyle(color: kMuted, height: 1.6, fontSize: 13.5)),
                ],
              ]),
            ),
          ),
        ),
        if (_related.isNotEmpty) ...[
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(18, 6, 18, 12), child: Text('সম্পর্কিত পণ্য', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: kInk)))),
          SliverToBoxAdapter(child: SizedBox(height: 258, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _related.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: 158, child: ProductCard(product: _related[i])),
          ))),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ]),
    );
  }

  Widget _bottomBar(BuildContext context, StoreState state, Map<String, dynamic> p, String cur, Color brand) {
    final total = ((p['price'] ?? 0) as num) * _qty;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))],
        ),
        child: Row(children: [
          Container(
            decoration: BoxDecoration(color: brandTint(brand, 0.08), borderRadius: BorderRadius.circular(13)),
            child: Row(children: [
              _stepBtn(Icons.remove_rounded, brand, () => setState(() => _qty = (_qty - 1).clamp(1, 999))),
              SizedBox(width: 30, child: Text('$_qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: brand))),
              _stepBtn(Icons.add_rounded, brand, () => setState(() => _qty = (_qty + 1).clamp(1, 999))),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
            onPressed: () {
              state.addToCart(p, _qty);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_qty টি কার্টে যোগ হয়েছে'), duration: const Duration(seconds: 1)));
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.shopping_cart_rounded, size: 18),
              const SizedBox(width: 8),
              const Text('কার্টে যোগ'),
              const SizedBox(width: 6),
              Text('• ${money(cur, total)}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _circle(IconData i, VoidCallback f) => Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(customBorder: const CircleBorder(), onTap: f, child: SizedBox(width: 40, height: 40, child: Icon(i, size: 20, color: kInk))),
        ),
      );

  Widget _stepBtn(IconData i, Color brand, VoidCallback f) => InkWell(onTap: f, borderRadius: BorderRadius.circular(13), child: SizedBox(width: 40, height: 46, child: Icon(i, size: 19, color: brand)));
}
