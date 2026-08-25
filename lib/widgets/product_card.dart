import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';
import '../screens/product_screen.dart';

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
    final qty = state.qtyOf(product['id'] as int);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(productId: product['id'] as int))),
      child: Container(
        decoration: softCard(radius: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(children: [
              Positioned.fill(
                child: img != null
                    ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                    : _ph(),
              ),
              if (off > 0)
                Positioned(left: 8, top: 8, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(6)),
                  child: Text('$off% ছাড়', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kInk, height: 1.25)),
              const SizedBox(height: 6),
              Row(children: [
                Text('$cur${money.n((product['price'] ?? 0) as num)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kInk)),
                if (off > 0) ...[
                  const SizedBox(width: 5),
                  Text('$cur${money.n((product['compare_price'] ?? 0) as num)}', style: const TextStyle(fontSize: 11, color: kFaint, decoration: TextDecoration.lineThrough)),
                ],
              ]),
              const SizedBox(height: 8),
              qty == 0
                  ? SizedBox(
                      width: double.infinity, height: 34,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: brand, side: BorderSide(color: brand), minimumSize: const Size.fromHeight(34), padding: EdgeInsets.zero),
                        onPressed: () => state.addToCart(product),
                        child: const Text('কার্টে যোগ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ),
                    )
                  : _Stepper(brand: brand, qty: qty, onMinus: () => state.setQty(product['id'] as int, qty - 1), onPlus: () => state.setQty(product['id'] as int, qty + 1)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _ph() => Container(color: const Color(0xFFF1F5F9), child: const Center(child: Text('🛍️', style: TextStyle(fontSize: 34))));
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.brand, required this.qty, required this.onMinus, required this.onPlus});
  final Color brand;
  final int qty;
  final VoidCallback onMinus, onPlus;
  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _btn(Icons.remove_rounded, onMinus),
          Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          _btn(Icons.add_rounded, onPlus),
        ]),
      );
  Widget _btn(IconData i, VoidCallback f) => InkWell(onTap: f, child: SizedBox(width: 38, height: 34, child: Icon(i, color: Colors.white, size: 18)));
}
