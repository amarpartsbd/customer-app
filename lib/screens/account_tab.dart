import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';
import 'orders_screen.dart';
import 'track_screen.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাকাউন্ট')),
      body: state.isLoggedIn ? const _LoggedIn() : const _Auth(),
    );
  }
}

/* ─────────── logged-in ─────────── */

class _LoggedIn extends StatelessWidget {
  const _LoggedIn();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final c = state.customer ?? {};
    final brand = state.brandColor;
    return ListView(padding: EdgeInsets.zero, children: [
      // Profile header
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: brandGradient(brand), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          CircleAvatar(radius: 30, backgroundColor: Colors.white.withValues(alpha: 0.2), child: Text((c['name']?.toString() ?? '?').characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.phone_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 5),
              Text(c['phone']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ])),
        ]),
      ),
      const SizedBox(height: 8),
      _menu(context, Icons.receipt_long_rounded, 'আমার অর্ডার', 'সব অর্ডার ও স্ট্যাটাস দেখুন', brand, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()))),
      _menu(context, Icons.local_shipping_rounded, 'অর্ডার ট্র্যাক করুন', 'অর্ডার নম্বর দিয়ে খুঁজুন', brand, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrackScreen()))),
      _menu(context, Icons.logout_rounded, 'লগআউট', 'অ্যাকাউন্ট থেকে বের হন', brand, () => state.logout(), danger: true),
    ]);
  }

  Widget _menu(BuildContext context, IconData icon, String label, String sub, Color brand, VoidCallback onTap, {bool danger = false}) {
    final color = danger ? kDanger : brand;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
            child: Row(children: [
              Container(height: 40, width: 40, decoration: BoxDecoration(color: danger ? kDanger.withValues(alpha: 0.1) : brandTint(brand, 0.10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: danger ? kDanger : kInk, fontSize: 14.5)),
                Text(sub, style: const TextStyle(fontSize: 11.5, color: kFaint)),
              ])),
              const Icon(Icons.chevron_right_rounded, color: kFaint),
            ]),
          ),
        ),
      ),
    );
  }
}

/* ─────────── guest auth ─────────── */

class _Auth extends StatefulWidget {
  const _Auth();
  @override
  State<_Auth> createState() => _AuthState();
}

class _AuthState extends State<_Auth> {
  bool _register = false;
  final _login = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final state = context.read<StoreState>();
    try {
      if (_register) {
        if (_name.text.trim().isEmpty || _phone.text.trim().length < 6 || _password.text.length < 6) {
          throw Exception('নাম, মোবাইল ও কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন।');
        }
        await state.register(_name.text.trim(), _phone.text.trim(), _email.text.trim().isEmpty ? null : _email.text.trim(), _password.text);
      } else {
        await state.login(_login.text.trim(), _password.text);
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<StoreState>().brandColor;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 8),
      Center(child: Container(height: 76, width: 76, decoration: BoxDecoration(color: brandTint(brand, 0.10), shape: BoxShape.circle), child: Icon(Icons.person_rounded, size: 40, color: brand))),
      const SizedBox(height: 14),
      Text(_register ? 'অ্যাকাউন্ট তৈরি করুন' : 'স্বাগতম!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: kInk)),
      const SizedBox(height: 4),
      Text(_register ? 'দ্রুত চেকআউট ও অর্ডার হিস্ট্রির জন্য' : 'আপনার অ্যাকাউন্টে প্রবেশ করুন', textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13)),
      const SizedBox(height: 22),

      // Segmented toggle
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFFEFF3ED), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          _seg('লগইন', !_register, brand, () => setState(() { _register = false; _error = null; })),
          _seg('রেজিস্টার', _register, brand, () => setState(() { _register = true; _error = null; })),
        ]),
      ),
      const SizedBox(height: 20),

      if (_register) ...[
        _f(_name, 'নাম', Icons.person_outline_rounded),
        _f(_phone, 'মোবাইল নম্বর', Icons.phone_outlined, keyboard: TextInputType.phone),
        _f(_email, 'ইমেইল (ঐচ্ছিক)', Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress),
        _f(_password, 'পাসওয়ার্ড', Icons.lock_outline_rounded, obscure: true),
      ] else ...[
        _f(_login, 'মোবাইল বা ইমেইল', Icons.person_outline_rounded),
        _f(_password, 'পাসওয়ার্ড', Icons.lock_outline_rounded, obscure: true),
      ],

      if (_error != null) Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [const Icon(Icons.error_outline_rounded, color: kDanger, size: 16), const SizedBox(width: 6), Expanded(child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12.5)))]),
      ),
      FilledButton(
        onPressed: _loading ? null : _submit,
        child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_register ? 'অ্যাকাউন্ট তৈরি করুন' : 'লগইন করুন'),
      ),
    ]);
  }

  Widget _seg(String label, bool active, Color brand, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: active ? kCardShadow : null,
            ),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: active ? brand : kMuted)),
          ),
        ),
      );

  Widget _f(TextEditingController c, String label, IconData icon, {bool obscure = false, TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c, obscureText: obscure, keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20, color: kFaint), fillColor: const Color(0xFFF8FAF7)),
        ),
      );
}
