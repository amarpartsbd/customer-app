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
    final cur = context.watch<StoreState>().currency;
    return Scaffold(
      appBar: AppBar(title: const Text('আমার অর্ডার')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snap.data ?? [];
          if (list.isEmpty) return const Center(child: Text('এখনো কোনো অর্ডার নেই।', style: TextStyle(color: kMuted)));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _tile(list[i], cur),
          );
        },
      ),
    );
  }

  Widget _tile(Map<String, dynamic> o, String cur) {
    final items = (o['items'] as List?) ?? [];
    final paid = o['paid'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: softCard(radius: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(o['order_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: statusColor(o['status'] ?? '').withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(o['status_label'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor(o['status'] ?? '')))),
        ]),
        const SizedBox(height: 4),
        Text('${items.length} টি পণ্য · ${paid ? 'পেইড' : (o['payment_method'] == 'cod' ? 'ক্যাশ অন ডেলিভারি' : 'পেমেন্ট বাকি')}', style: const TextStyle(fontSize: 12, color: kMuted)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 2, children: [
          for (final it in items.take(3)) Text('${it['name']} × ${(it['quantity'] as num).toInt()}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
          if (items.length > 3) Text('+${items.length - 3} আরও', style: const TextStyle(fontSize: 12.5, color: kFaint)),
        ]),
        const Divider(height: 18),
        Align(alignment: Alignment.centerRight, child: Text(money(cur, (o['total'] ?? 0) as num), style: const TextStyle(fontWeight: FontWeight.w800, color: kInk, fontSize: 15))),
      ]),
    );
  }
}
