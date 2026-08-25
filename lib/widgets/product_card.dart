import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';
import '../screens/product_screen.dart';

/// Fresh grocery-style product card: tinted image, discount badge, unit line,
/// bold price and a circular add button that expands into a compact stepper.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final brand = state.brandColor;
    final cur = state.currency;
    final off = (product['discount_percent'] ?? 0) as int;
    final img = product['image']?.toString();
    final unit = (product['unit'] ?? '').toString();
    final qty = state.qtyOf(product['id'] as int);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(productId: product['id'] as int))),
      child: Container(
        decoration: softCard(radius: 18),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          AspectRatio(
            aspectRatio: 1.04,
            child: Stack(children: [
              Positioned.fill(
                child: Container(
                  color: brandTint(brand, 0.05),
                  padding: const EdgeInsets.all(8),
                  child: img != null
                      ? Image.network(img, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _ph())
                      : _ph(),
                ),
              ),
              if (off > 0)
                Positioned(left: 8, top: 8, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(20)),
                  child: Text('-$off%', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                )),
            ]),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk, height: 1.2)),
              const SizedBox(height: 2),
              Text(unit.isNotEmpty ? unit : 'প্রতি একক', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: kFaint)),
              const SizedBox(height: 9),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    if (off > 0)
                      Text('$cur${money.n((product['compare_price'] ?? 0) as num)}', style: const TextStyle(fontSize: 11, color: kFaint, decoration: TextDecoration.lineThrough)),
                    Text('$cur${money.n((product['price'] ?? 0) as num)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: brand, height: 1.1)),
                  ]),
                ),
                const SizedBox(width: 6),
                qty == 0
                    ? _AddButton(brand: brand, onTap: () => state.addToCart(product))
                    : _Stepper(brand: brand, qty: qty, onMinus: () => state.setQty(product['id'] as int, qty - 1), onPlus: () => state.setQty(product['id'] as int, qty + 1)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _ph() => const Center(child: Text('🛍️', style: TextStyle(fontSize: 40)));
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.brand, required this.onTap});
  final Color brand;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: brand,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: const SizedBox(width: 36, height: 36, child: Icon(Icons.add_rounded, color: Colors.white, size: 22)),
        ),
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.brand, required this.qty, required this.onMinus, required this.onPlus});
  final Color brand;
  final int qty;
  final VoidCallback onMinus, onPlus;
  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(11)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _btn(Icons.remove_rounded, onMinus),
          Container(constraints: const BoxConstraints(minWidth: 20), alignment: Alignment.center, child: Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
          _btn(Icons.add_rounded, onPlus),
        ]),
      );
  Widget _btn(IconData i, VoidCallback f) => InkWell(onTap: f, borderRadius: BorderRadius.circular(11), child: SizedBox(width: 32, height: 36, child: Icon(i, color: Colors.white, size: 17)));
}
