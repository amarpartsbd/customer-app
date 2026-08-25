import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future<List<Map<String, dynamic>>>? _future;
  @override
  void initState() {
    super.initState();
    _future = context.read<StoreState>().api.get('/orders').then((d) => (d['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final cur = state.currency;
    final brand = state.brandColor;
    return Scaffold(
      appBar: AppBar(title: const Text('আমার অর্ডার')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: brand));
          final list = snap.data ?? [];
          if (list.isEmpty) return _empty(brand);
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _tile(list[i], cur, brand),
          );
        },
      ),
    );
  }

  Widget _tile(Map<String, dynamic> o, String cur, Color brand) {
    final items = (o['items'] as List?) ?? [];
    final paid = o['paid'] == true;
    final sc = statusColor(o['status'] ?? '');
    final date = (o['date'] ?? o['created_at'] ?? '').toString();
    return Container(
      decoration: softCard(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
          child: Row(children: [
            Container(height: 38, width: 38, decoration: BoxDecoration(color: brandTint(brand, 0.10), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.receipt_long_rounded, size: 19, color: brand)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o['order_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, color: kInk, fontSize: 14.5)),
              if (date.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(date, style: const TextStyle(fontSize: 11.5, color: kFaint))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(o['status_label'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
            ),
          ]),
        ),
        Container(height: 1, color: kLine),
        // Items
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final it in items.take(3))
              Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
                const Text('•  ', style: TextStyle(color: kFaint)),
                Expanded(child: Text(it['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: kMuted))),
                Text('× ${(it['quantity'] as num).toInt()}', style: const TextStyle(fontSize: 12.5, color: kMuted, fontWeight: FontWeight.w600)),
              ])),
            if (items.length > 3) Text('  +${items.length - 3} টি আরও পণ্য', style: const TextStyle(fontSize: 12, color: kFaint)),
          ]),
        ),
        // Footer
        Container(
          color: const Color(0xFFFAFBF9),
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          child: Row(children: [
            Icon(paid ? Icons.verified_rounded : Icons.payments_outlined, size: 15, color: paid ? kSuccess : kMuted),
            const SizedBox(width: 5),
            Text(paid ? 'পেইড' : (o['payment_method'] == 'cod' ? 'ক্যাশ অন ডেলিভারি' : 'পেমেন্ট বাকি'), style: TextStyle(fontSize: 11.5, color: paid ? kSuccess : kMuted, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(money(cur, (o['total'] ?? 0) as num), style: TextStyle(fontWeight: FontWeight.w800, color: brand, fontSize: 16)),
          ]),
        ),
      ]),
    );
  }

  Widget _empty(Color brand) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(height: 96, width: 96, decoration: BoxDecoration(color: brandTint(brand, 0.08), shape: BoxShape.circle), child: Icon(Icons.receipt_long_rounded, size: 44, color: brand)),
        const SizedBox(height: 16),
        const Text('এখনো কোনো অর্ডার নেই', style: TextStyle(color: kInk, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('কেনাকাটা শুরু করলে অর্ডার এখানে দেখাবে', style: TextStyle(color: kMuted, fontSize: 13)),
      ]));
}
