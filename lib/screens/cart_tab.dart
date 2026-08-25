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
      appBar: AppBar(title: Text('আপনার কার্ট${state.cartCount > 0 ? ' (${state.cartCount})' : ''}'), actions: [
        if (lines.isNotEmpty) TextButton(onPressed: () => state.clearCart(), child: const Text('খালি করুন', style: TextStyle(color: kDanger))),
      ]),
      body: lines.isEmpty
          ? _empty()
          : Column(children: [
              if ((state.config['free_delivery_over'] as num?) != null && (state.config['free_delivery_over'] as num) > 0)
                _freeBar(state, cur),
              Expanded(child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _tile(context, state, lines[i], cur, brand),
              )),
              _summary(context, state, cur, brand),
            ]),
    );
  }

  Widget _freeBar(StoreState s, String cur) {
    final over = (s.config['free_delivery_over'] as num).toDouble();
    final remaining = (over - s.cartSubtotal).clamp(0, over);
    final reached = s.cartSubtotal >= over;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.local_shipping_rounded, color: kSuccess, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(reached ? '🎉 আপনি ফ্রি ডেলিভারি পাচ্ছেন!' : 'আরও $cur${money.n(remaining)} যোগ করুন, ফ্রি ডেলিভারি পেতে!', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF047857)))),
      ]),
    );
  }

  Widget _tile(BuildContext context, StoreState s, Map<String, dynamic> l, String cur, Color brand) {
    final p = Map<String, dynamic>.from(l['product']);
    final qty = l['qty'] as int;
    final id = p['id'] as int;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: softCard(radius: 14),
      child: Row(children: [
        Container(height: 60, width: 60, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)), clipBehavior: Clip.antiAlias,
          child: p['image'] != null ? Image.network(p['image'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🛍️'))) : const Center(child: Text('🛍️'))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kInk)),
          const SizedBox(height: 4),
          Text(money(cur, (p['price'] ?? 0) as num), style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        ])),
        Column(children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: kLine)),
            child: Row(children: [
              _sb(Icons.remove_rounded, () => s.setQty(id, qty - 1)),
              SizedBox(width: 26, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
              _sb(Icons.add_rounded, () => s.setQty(id, qty + 1)),
            ]),
          ),
          const SizedBox(height: 4),
          Text(money(cur, ((p['price'] ?? 0) as num) * qty), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk)),
        ]),
      ]),
    );
  }

  Widget _sb(IconData i, VoidCallback f) => InkWell(onTap: f, child: SizedBox(width: 30, height: 30, child: Icon(i, size: 16, color: kMuted)));

  Widget _summary(BuildContext context, StoreState s, String cur, Color brand) {
    final free = s.deliveryCharge == 0 && (s.config['free_delivery_over'] as num?) != null && s.cartSubtotal >= ((s.config['free_delivery_over'] as num?)?.toDouble() ?? double.infinity);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _row('সাবটোটাল', money(cur, s.cartSubtotal)),
        const SizedBox(height: 5),
        _row('ডেলিভারি চার্জ', free ? 'ফ্রি' : money(cur, s.deliveryCharge), valueColor: free ? kSuccess : null),
        const Divider(height: 18),
        _row('মোট পরিশোধ', money(cur, s.cartTotal), bold: true),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
          child: const Text('চেকআউট করুন'),
        )),
      ]),
    );
  }

  Widget _row(String k, String v, {bool bold = false, Color? valueColor}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(k, style: TextStyle(color: bold ? kInk : kMuted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 13.5)),
        Text(v, style: TextStyle(color: valueColor ?? kInk, fontWeight: FontWeight.w800, fontSize: bold ? 18 : 13.5)),
      ]);

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.shopping_cart_outlined, size: 64, color: kFaint),
        SizedBox(height: 12),
        Text('আপনার কার্ট খালি।', style: TextStyle(color: kMuted)),
      ]));
}
