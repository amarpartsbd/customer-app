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
    final state = context.watch<StoreState>();
    final brand = state.brandColor;
    final cur = state.currency;
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('অর্ডার ট্র্যাক')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Search card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: softCard(radius: 16),
          child: Column(children: [
            TextField(controller: _order, decoration: InputDecoration(labelText: 'অর্ডার নম্বর', hintText: 'যেমন: DT-000123', prefixIcon: const Icon(Icons.tag_rounded, size: 20, color: kFaint), fillColor: const Color(0xFFF8FAF7))),
            const SizedBox(height: 12),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'মোবাইল নম্বর', prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: kFaint), fillColor: const Color(0xFFF8FAF7))),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Row(children: [const Icon(Icons.error_outline_rounded, color: kDanger, size: 16), const SizedBox(width: 6), Expanded(child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12.5)))])),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: _loading ? null : _track,
              child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('ট্র্যাক করুন'),
            )),
          ]),
        ),

        if (r != null && r['found'] == true) ...[
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(16), decoration: softCard(radius: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(r['order_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kInk)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor(r['status'] ?? '').withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(r['status_label'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: statusColor(r['status'] ?? ''), fontSize: 12.5)),
              ),
            ]),
            const SizedBox(height: 20),

            if (r['cancelled'] == true)
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: kDanger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [const Icon(Icons.cancel_rounded, color: kDanger, size: 18), const SizedBox(width: 8), Expanded(child: Text('এই অর্ডারটি ${r['status_label']} হয়েছে।', style: const TextStyle(color: kDanger, fontWeight: FontWeight.w600)))]),
              )
            else
              _timeline((r['step'] as int?) ?? 1, brand),

            Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Container(height: 1, color: kLine)),

            _info(Icons.payments_rounded, 'সর্বমোট', money(cur, (r['total'] ?? 0) as num), brand, valueBold: true),
            const SizedBox(height: 10),
            _info(Icons.person_rounded, 'গ্রাহক', '${r['shipping_name'] ?? ''} · ${r['shipping_phone'] ?? ''}', brand),
            const SizedBox(height: 10),
            _info(Icons.location_on_rounded, 'ঠিকানা', r['shipping_address'] ?? '', brand),
          ])),
        ],
      ]),
    );
  }

  Widget _timeline(int step, Color brand) => Column(children: [
        Row(children: [
          for (int i = 0; i < 4; i++) ...[
            _dot(i, i + 1 < step, i + 1 == step, brand),
            if (i < 3) Expanded(child: Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: i + 1 < step ? brand : kLine, borderRadius: BorderRadius.circular(2)))),
          ],
        ]),
        const SizedBox(height: 8),
        Row(children: [
          for (int i = 0; i < 4; i++)
            Expanded(child: Text(_steps[i][1], textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: i + 1 <= step ? kInk : kFaint, fontWeight: i + 1 == step ? FontWeight.w700 : FontWeight.w500))),
        ]),
      ]);

  Widget _dot(int index, bool done, bool current, Color brand) {
    final active = done || current;
    return Container(
      height: 42, width: 42,
      decoration: BoxDecoration(
        color: active ? brand : brandTint(brand, 0.08),
        shape: BoxShape.circle,
        border: current ? Border.all(color: brandTint(brand, 0.30), width: 3) : null,
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
          : Text(_steps[index][0], style: TextStyle(fontSize: 17, color: active ? Colors.white : null)),
    );
  }

  Widget _info(IconData icon, String label, String value, Color brand, {bool valueBold = false}) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 17, color: kFaint),
        const SizedBox(width: 10),
        SizedBox(width: 56, child: Text(label, style: const TextStyle(fontSize: 12.5, color: kFaint))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12.5, color: kInk, fontWeight: valueBold ? FontWeight.w800 : FontWeight.w500))),
      ]);
}
