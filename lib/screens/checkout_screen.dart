import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/store_state.dart';
import '../theme.dart';
import 'order_success_screen.dart';
import '../skin.dart';
import '../widgets/animated_money.dart';
import '../widgets/nf_weight_note.dart';

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
    final brand = state.brandColor;
    final free = state.deliveryCharge == 0 && (state.config['free_delivery_over'] as num?) != null && state.cartSubtotal >= ((state.config['free_delivery_over'] as num?)?.toDouble() ?? double.infinity);
    final onlineEnabled = state.config['online_payment_enabled'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('চেকআউট')),
      bottomNavigationBar: SafeArea(child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))]),
        child: FilledButton(
          onPressed: _saving ? null : _place,
          child: _saving
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_rounded, size: 17),
                  const SizedBox(width: 8),
                  const Text('অর্ডার কনফার্ম'),
                  const SizedBox(width: 6),
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.w800)),
                  AnimatedMoney(state.cartTotal, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
                ]),
        ),
      )),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (!state.isLoggedIn)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: brandTint(brand, 0.07), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(Icons.info_rounded, color: brand, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('গেস্ট হিসেবে অর্ডার করছেন। লগইন করলে দ্রুত চেকআউট ও অর্ডার হিস্ট্রি পাবেন।', style: TextStyle(fontSize: 12, color: kMuted))),
            ]),
          ),

        // Delivery
        _card('ডেলিভারি তথ্য', Icons.location_on_rounded, brand, [
          _field(_name, 'নাম', Icons.person_outline_rounded),
          _field(_phone, 'মোবাইল নম্বর', Icons.phone_outlined, keyboard: TextInputType.phone),
          _field(_address, 'সম্পূর্ণ ঠিকানা', Icons.home_outlined, maxLines: 2),
          _field(_city, 'শহর / এলাকা (ঐচ্ছিক)', Icons.location_city_outlined),
          _field(_notes, 'অর্ডার নোট (ঐচ্ছিক)', Icons.edit_note_rounded, maxLines: 2, last: true),
        ]),
        const SizedBox(height: 14),

        // Payment
        _card('পেমেন্ট পদ্ধতি', Icons.payments_outlined, brand, [
          _payTile('cod', '💵', 'ক্যাশ অন ডেলিভারি', 'পণ্য হাতে পেয়ে টাকা দিন', brand),
          if (onlineEnabled) ...[const SizedBox(height: 8), _payTile('online', '💳', 'অনলাইন পেমেন্ট', 'bKash · নগদ · কার্ড', brand)],
        ]),
        const SizedBox(height: 14),

        // Summary
        _card('অর্ডার সারাংশ', Icons.receipt_long_rounded, brand, [
          if (state.isNf) ...[
            // Each item with its amount, like the website's checkout.
            for (final l in state.cartLines) Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((l['product']['name_en'] ?? l['product']['name'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: Nf.t(13.5, w: FontWeight.w600)),
                  Text(bnQty(l['qty'] as num, Map<String, dynamic>.from(l['product'])), style: Nf.t(12, color: Nf.muted2)),
                ])),
                AnimatedMoney(state.lineTotal(l), style: Nf.t(13.5, w: FontWeight.w600)),
              ]),
            ),
            const Divider(height: 14),
          ],
          _row(state.isNf ? 'পণ্যের দাম' : 'পণ্য (${state.cartCount})', null, amount: state.cartSubtotal),
          const SizedBox(height: 7),
          free ? _row('ডেলিভারি চার্জ', 'ফ্রি', valueColor: kSuccess) : _row('ডেলিভারি চার্জ', null, amount: state.deliveryCharge),
          const Padding(padding: EdgeInsets.symmetric(vertical: 11), child: Divider(height: 1)),
          _row(state.isNf ? 'মোট' : 'সর্বমোট', null, amount: state.cartTotal, bold: true, valueColor: state.isNf ? Nf.red : null),
          if (state.isNf && NfWeightNote.kindsIn(state.cartLines.map((l) => Map<String, dynamic>.from(l['product']))).isNotEmpty) ...[
            const SizedBox(height: 12),
            NfWeightNote(kinds: NfWeightNote.kindsIn(state.cartLines.map((l) => Map<String, dynamic>.from(l['product'])))),
          ],
          if (state.isNf) ...[
            const SizedBox(height: 10),
            Text('ডেলিভারি ২৪–৪৮ ঘণ্টার মধ্যে। কাটার পর ওজনে ±৫০ গ্রাম তারতম্য হতে পারে।', style: Nf.t(12, color: Nf.muted2)),
          ],
        ]),

        if (_error != null) Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: kDanger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.error_outline_rounded, color: kDanger, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12.5)))]),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _card(String title, IconData icon, Color brand, List<Widget> children) => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: softCard(radius: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(height: 28, width: 28, decoration: BoxDecoration(color: brandTint(brand, 0.10), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 16, color: brand)),
            const SizedBox(width: 9),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk, fontSize: 14.5)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ]),
      );

  Widget _field(TextEditingController c, String label, IconData icon, {TextInputType? keyboard, int maxLines = 1, bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 10),
        child: TextField(
          controller: c, keyboardType: keyboard, maxLines: maxLines,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20, color: kFaint), fillColor: const Color(0xFFF8FAF7)),
        ),
      );

  Widget _payTile(String value, String emoji, String title, String sub, Color brand) {
    final sel = _pay == value;
    return GestureDetector(
      onTap: () => setState(() => _pay = value),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: sel ? brandTint(brand, 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: sel ? brand : kLine, width: sel ? 1.8 : 1),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk, fontSize: 14)),
            Text(sub, style: const TextStyle(fontSize: 11.5, color: kMuted)),
          ])),
          Icon(sel ? Icons.check_circle_rounded : Icons.circle_outlined, color: sel ? brand : kFaint, size: 22),
        ]),
      ),
    );
  }

  /// A summary row: plain text [v], or a money [amount] that rolls to its new value.
  Widget _row(String k, String? v, {num? amount, bool bold = false, Color? valueColor}) {
    final st = TextStyle(color: valueColor ?? kInk, fontWeight: FontWeight.w800, fontSize: bold ? 18 : 13.5);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: TextStyle(color: bold ? kInk : kMuted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 13.5)),
      amount != null ? AnimatedMoney(amount, style: st) : Text(v ?? '', style: st),
    ]);
  }
}
