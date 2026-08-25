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
    return Scaffold(
      appBar: AppBar(title: Text(p?['name'] ?? 'পণ্য')),
      bottomNavigationBar: p == null ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
              child: Row(children: [
                _stepBtn(Icons.remove_rounded, () => setState(() => _qty = (_qty - 1).clamp(1, 999))),
                SizedBox(width: 34, child: Text('$_qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                _stepBtn(Icons.add_rounded, () => setState(() => _qty = (_qty + 1).clamp(1, 999))),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(child: FilledButton.icon(
              onPressed: () {
                state.addToCart(p, _qty);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কার্টে যোগ হয়েছে')));
              },
              icon: const Icon(Icons.shopping_cart_rounded, size: 18),
              label: const Text('কার্টে যোগ করুন'),
            )),
          ]),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : p == null
              ? const Center(child: Text('পণ্য পাওয়া যায়নি।', style: TextStyle(color: kMuted)))
              : ListView(children: [
                  AspectRatio(aspectRatio: 1, child: p['image'] != null
                      ? Image.network(p['image'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF1F5F9), child: const Center(child: Text('🛍️', style: TextStyle(fontSize: 60)))))
                      : Container(color: const Color(0xFFF1F5F9), child: const Center(child: Text('🛍️', style: TextStyle(fontSize: 60))))),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if ((p['category'] ?? '').toString().isNotEmpty)
                        Text(p['category'].toString().toUpperCase(), style: TextStyle(color: brand, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                      const SizedBox(height: 4),
                      Text(p['name'] ?? '', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: kInk, height: 1.25)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: const Text('স্টকে আছে', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kSuccess))),
                        if ((p['sku'] ?? '').toString().isNotEmpty) ...[const SizedBox(width: 8), Text('SKU: ${p['sku']}', style: const TextStyle(fontSize: 11, color: kFaint))],
                      ]),
                      const SizedBox(height: 14),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(money(cur, (p['price'] ?? 0) as num), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kInk)),
                        if (((p['discount_percent'] ?? 0) as int) > 0) ...[
                          const SizedBox(width: 8),
                          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(money(cur, (p['compare_price'] ?? 0) as num), style: const TextStyle(fontSize: 15, color: kFaint, decoration: TextDecoration.lineThrough))),
                          const SizedBox(width: 8),
                          Padding(padding: const EdgeInsets.only(bottom: 4), child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: kDanger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text('${p['discount_percent']}% ছাড়', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kDanger)))),
                        ],
                      ]),
                      if ((p['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Text('বিবরণ', style: TextStyle(fontWeight: FontWeight.w800, color: kInk)),
                        const SizedBox(height: 6),
                        Text(p['description'], style: const TextStyle(color: kMuted, height: 1.5)),
                      ],
                    ]),
                  ),
                  if (_related.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 10), child: Text('সম্পর্কিত পণ্য', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kInk))),
                    SizedBox(height: 250, child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _related.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => SizedBox(width: 150, child: ProductCard(product: _related[i])),
                    )),
                    const SizedBox(height: 16),
                  ],
                ]),
    );
  }

  Widget _stepBtn(IconData i, VoidCallback f) => InkWell(onTap: f, child: SizedBox(width: 40, height: 46, child: Icon(i, size: 18, color: kMuted)));
}
