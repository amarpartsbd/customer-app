import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});
  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _order = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone.text = context.read<StoreState>().customer?['phone']?.toString() ?? '';
  }

  Future<void> _track() async {
    if (_order.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      setState(() => _error = 'অর্ডার নম্বর ও মোবাইল দিন।');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final d = await context.read<StoreState>().api.post('/track', body: {'order_number': _order.text.trim(), 'phone': _phone.text.trim()});
      setState(() { _result = Map<String, dynamic>.from(d); _loading = false; });
    } catch (e) {
      setState(() { _error = 'এই তথ্যের কোনো অর্ডার পাওয়া যায়নি।'; _loading = false; });
    }
  }

  static const _steps = [['📥', 'কনফার্ম'], ['📦', 'প্যাকিং'], ['🚚', 'পথে'], ['✅', 'ডেলিভারড']];

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<StoreState>().brandColor;
    final cur = context.watch<StoreState>().currency;
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('অর্ডার ট্র্যাক')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _order, decoration: const InputDecoration(labelText: 'অর্ডার নম্বর', hintText: 'যেমন: DT-000123')),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'মোবাইল নম্বর')),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12.5))),
        const SizedBox(height: 14),
        FilledButton(onPressed: _loading ? null : _track, child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('ট্র্যাক করুন')),
        if (r != null && r['found'] == true) ...[
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16), decoration: softCard(radius: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(r['order_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kInk)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor(r['status'] ?? '').withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(r['status_label'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: statusColor(r['status'] ?? ''), fontSize: 12.5))),
            ]),
            const SizedBox(height: 18),
            if (r['cancelled'] == true)
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kDanger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Text('এই অর্ডারটি ${r['status_label']} হয়েছে।', style: const TextStyle(color: kDanger, fontWeight: FontWeight.w600)))
            else
              Row(children: [
                for (int i = 0; i < 4; i++) ...[
                  _stepDot(i, i + 1 <= (r['step'] as int), brand),
                  if (i < 3) Expanded(child: Container(height: 3, color: i + 1 < (r['step'] as int) ? brand : kLine)),
                ],
              ]),
            if (r['cancelled'] != true) ...[
              const SizedBox(height: 6),
              Row(children: [for (final s in _steps) Expanded(child: Text(s[1], textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: kMuted)))]),
            ],
            const Divider(height: 24),
            Text('মোট: ${money(cur, (r['total'] ?? 0) as num)}', style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 4),
            Text('${r['shipping_name']} · ${r['shipping_phone']}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
            Text(r['shipping_address'] ?? '', style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ])),
        ],
      ]),
    );
  }

  Widget _stepDot(int index, bool done, Color brand) => Container(
        height: 40, width: 40,
        decoration: BoxDecoration(color: done ? brand : const Color(0xFFF1F5F9), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(_steps[index][0], style: const TextStyle(fontSize: 16)),
      );
}
