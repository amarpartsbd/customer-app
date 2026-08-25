import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';
import 'checkout_screen.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final cur = state.currency;
    final brand = state.brandColor;
    final lines = state.cartLines;

    return Scaffold(
      appBar: AppBar(
        title: Text('আপনার কার্ট${state.cartCount > 0 ? ' (${state.cartCount})' : ''}'),
        actions: [
          if (lines.isNotEmpty)
            TextButton.icon(
              onPressed: () => state.clearCart(),
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: kDanger),
              label: const Text('খালি করুন', style: TextStyle(color: kDanger, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: lines.isEmpty
          ? _empty(context, brand)
          : Column(children: [
              if ((state.config['free_delivery_over'] as num?) != null && (state.config['free_delivery_over'] as num) > 0)
                _freeBar(state, cur, brand),
              Expanded(child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: lines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _tile(context, state, lines[i], cur, brand),
              )),
              _summary(context, state, cur, brand),
            ]),
    );
  }

  Widget _freeBar(StoreState s, String cur, Color brand) {
    final over = (s.config['free_delivery_over'] as num).toDouble();
    final remaining = (over - s.cartSubtotal).clamp(0, over).toDouble();
    final reached = s.cartSubtotal >= over;
    final pct = (s.cartSubtotal / over).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: brandTint(brand, 0.07), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(reached ? Icons.check_circle_rounded : Icons.local_shipping_rounded, color: brand, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            reached ? '🎉 আপনি ফ্রি ডেলিভারি পাচ্ছেন!' : 'আরও $cur${money.n(remaining)} যোগ করলেই ফ্রি ডেলিভারি!',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color.lerp(brand, Colors.black, 0.15)),
          )),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: Colors.white, valueColor: AlwaysStoppedAnimation(brand)),
        ),
      ]),
    );
  }

  Widget _tile(BuildContext context, StoreState s, Map<String, dynamic> l, String cur, Color brand) {
    final p = Map<String, dynamic>.from(l['product']);
    final qty = l['qty'] as int;
    final id = p['id'] as int;
    final unit = (p['unit'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: softCard(radius: 16),
      child: Row(children: [
        Container(
          height: 64, width: 64,
          decoration: BoxDecoration(color: brandTint(brand, 0.05), borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(5),
          child: p['image'] != null
              ? Image.network(p['image'], fit: BoxFit.contain, errorBuilder: (_, _, _) => const Center(child: Text('🛍️')))
              : const Center(child: Text('🛍️', style: TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(p['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: kInk))),
            InkWell(onTap: () => s.removeFromCart(id), borderRadius: BorderRadius.circular(20), child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.close_rounded, size: 17, color: kFaint))),
          ]),
          if (unit.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 1), child: Text(unit, style: const TextStyle(fontSize: 11, color: kFaint))),
          const SizedBox(height: 8),
          Row(children: [
            Text(money(cur, ((p['price'] ?? 0) as num) * qty), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: brand)),
            const Spacer(),
            _Stepper(brand: brand, qty: qty, onMinus: () => s.setQty(id, qty - 1), onPlus: () => s.setQty(id, qty + 1)),
          ]),
        ])),
      ]),
    );
  }

  Widget _summary(BuildContext context, StoreState s, String cur, Color brand) {
    final over = (s.config['free_delivery_over'] as num?)?.toDouble();
    final free = s.deliveryCharge == 0 && over != null && s.cartSubtotal >= over;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, -6))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _row('সাবটোটাল', money(cur, s.cartSubtotal)),
        const SizedBox(height: 7),
        _row('ডেলিভারি চার্জ', free ? 'ফ্রি' : money(cur, s.deliveryCharge), valueColor: free ? kSuccess : null),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: DashedLine()),
        _row('সর্বমোট', money(cur, s.cartTotal), bold: true),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('চেকআউট করুন'),
            const SizedBox(width: 8),
            Text('• ${money(cur, s.cartTotal)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        )),
      ]),
    );
  }

  Widget _row(String k, String v, {bool bold = false, Color? valueColor}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(k, style: TextStyle(color: bold ? kInk : kMuted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 13.5)),
        Text(v, style: TextStyle(color: valueColor ?? kInk, fontWeight: FontWeight.w800, fontSize: bold ? 18 : 13.5)),
      ]);

  Widget _empty(BuildContext context, Color brand) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(height: 96, width: 96, decoration: BoxDecoration(color: brandTint(brand, 0.08), shape: BoxShape.circle), child: Icon(Icons.shopping_cart_outlined, size: 44, color: brand)),
        const SizedBox(height: 16),
        const Text('আপনার কার্ট খালি', style: TextStyle(color: kInk, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('পছন্দের পণ্য যোগ করে কেনাকাটা শুরু করুন', style: TextStyle(color: kMuted, fontSize: 13)),
      ]));
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.brand, required this.qty, required this.onMinus, required this.onPlus});
  final Color brand;
  final int qty;
  final VoidCallback onMinus, onPlus;
  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _btn(Icons.remove_rounded, onMinus),
          Container(constraints: const BoxConstraints(minWidth: 22), alignment: Alignment.center, child: Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
          _btn(Icons.add_rounded, onPlus),
        ]),
      );
  Widget _btn(IconData i, VoidCallback f) => InkWell(onTap: f, borderRadius: BorderRadius.circular(10), child: SizedBox(width: 32, height: 34, child: Icon(i, color: Colors.white, size: 17)));
}

/// A thin dashed divider for the summary sheet.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final count = (c.maxWidth / 8).floor();
        return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(count, (_) => const SizedBox(width: 4, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: kLine)))));
      });
}
