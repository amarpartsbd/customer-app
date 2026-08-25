import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/store_state.dart';
import '../theme.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _notes = TextEditingController();
  String _pay = 'cod';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = context.read<StoreState>().customer;
    if (c != null) {
      _name.text = c['name']?.toString() ?? '';
      _phone.text = c['phone']?.toString() ?? '';
      _address.text = c['address']?.toString() ?? '';
      _city.text = c['city']?.toString() ?? '';
    }
  }

  Future<void> _place() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().length < 6 || _address.text.trim().isEmpty) {
      setState(() => _error = 'নাম, মোবাইল ও ঠিকানা দিন।');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final state = context.read<StoreState>();
    try {
      final res = await state.checkout(
        name: _name.text.trim(), phone: _phone.text.trim(), address: _address.text.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        paymentMethod: _pay,
      );
      if (!mounted) return;
      if (res['payment_url'] != null) {
        // Online payment — open the gateway. Order is placed (pending) on the server.
        final uri = Uri.parse(res['payment_url']);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        state.clearCart();
        if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderNumber: res['order_number'], online: true)), (r) => r.isFirst);
      } else {
        state.clearCart();
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderNumber: res['order_number'])), (r) => r.isFirst);
      }
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final cur = state.currency;
    final free = state.deliveryCharge == 0 && (state.config['free_delivery_over'] as num?) != null && state.cartSubtotal >= ((state.config['free_delivery_over'] as num?)?.toDouble() ?? double.infinity);
    final onlineEnabled = state.config['online_payment_enabled'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('চেকআউট')),
      bottomNavigationBar: SafeArea(child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: _saving ? null : _place,
          child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('অর্ডার কনফার্ম করুন · ${money(cur, state.cartTotal)}'),
        ),
      )),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (!state.isLoggedIn)
          Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: const Text('গেস্ট হিসেবে অর্ডার করছেন। অ্যাকাউন্ট থাকলে লগইন করে দ্রুত চেকআউট করুন।', style: TextStyle(fontSize: 12, color: kMuted))),
        const Text('ডেলিভারি তথ্য', style: TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        const SizedBox(height: 10),
        _field(_name, 'নাম'),
        _field(_phone, 'মোবাইল নম্বর', keyboard: TextInputType.phone),
        _field(_address, 'সম্পূর্ণ ঠিকানা', maxLines: 2),
        _field(_city, 'শহর / এলাকা (ঐচ্ছিক)'),
        _field(_notes, 'অর্ডার নোট (ঐচ্ছিক)', maxLines: 2),
        const SizedBox(height: 8),
        const Text('পেমেন্ট পদ্ধতি', style: TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        const SizedBox(height: 8),
        _payTile('cod', '💵 ক্যাশ অন ডেলিভারি', 'পণ্য হাতে পেয়ে টাকা দিন'),
        if (onlineEnabled) _payTile('online', '💳 অনলাইন পেমেন্ট', 'bKash · নগদ · কার্ড'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14), decoration: softCard(radius: 14),
          child: Column(children: [
            _row('সাবটোটাল', money(cur, state.cartSubtotal)),
            const SizedBox(height: 5),
            _row('ডেলিভারি চার্জ', free ? 'ফ্রি' : money(cur, state.deliveryCharge)),
            const Divider(height: 18),
            _row('মোট', money(cur, state.cartTotal), bold: true),
          ]),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: kDanger))),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _field(TextEditingController c, String label, {TextInputType? keyboard, int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: c, keyboardType: keyboard, maxLines: maxLines, decoration: InputDecoration(labelText: label)),
      );

  Widget _payTile(String value, String title, String sub) {
    final sel = _pay == value;
    final brand = context.read<StoreState>().brandColor;
    return GestureDetector(
      onTap: () => setState(() => _pay = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? brand : kLine, width: sel ? 2 : 1)),
        child: Row(children: [
          Icon(sel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: sel ? brand : kFaint, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
            Text(sub, style: const TextStyle(fontSize: 12, color: kMuted)),
          ])),
        ]),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(k, style: TextStyle(color: bold ? kInk : kMuted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 13.5)),
        Text(v, style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: bold ? 17 : 13.5)),
      ]);
}
