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
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        CircleAvatar(radius: 28, backgroundColor: brand, child: Text((c['name']?.toString() ?? '?').characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['name']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
          Text(c['phone']?.toString() ?? '', style: const TextStyle(color: kMuted)),
        ])),
      ]),
      const SizedBox(height: 20),
      _menu(context, Icons.receipt_long_rounded, 'আমার অর্ডার', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()))),
      _menu(context, Icons.local_shipping_rounded, 'অর্ডার ট্র্যাক করুন', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrackScreen()))),
      _menu(context, Icons.logout_rounded, 'লগআউট', () => state.logout(), danger: true),
    ]);
  }

  Widget _menu(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool danger = false}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: softCard(radius: 14),
        child: ListTile(
          leading: Icon(icon, color: danger ? kDanger : context.read<StoreState>().brandColor),
          title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: danger ? kDanger : kInk)),
          trailing: const Icon(Icons.chevron_right_rounded, color: kFaint),
          onTap: onTap,
        ),
      );
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
      const SizedBox(height: 10),
      Icon(Icons.person_pin_circle_rounded, size: 60, color: brand),
      const SizedBox(height: 8),
      Text(_register ? 'রেজিস্টার করুন' : 'লগইন করুন', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
      const SizedBox(height: 4),
      Text(_register ? 'দ্রুত চেকআউট ও অর্ডার হিস্ট্রির জন্য' : 'আপনার অ্যাকাউন্টে প্রবেশ করুন', textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13)),
      const SizedBox(height: 24),
      if (_register) ...[
        _f(_name, 'নাম'),
        _f(_phone, 'মোবাইল নম্বর', keyboard: TextInputType.phone),
        _f(_email, 'ইমেইল (ঐচ্ছিক)', keyboard: TextInputType.emailAddress),
        _f(_password, 'পাসওয়ার্ড', obscure: true),
      ] else ...[
        _f(_login, 'মোবাইল বা ইমেইল'),
        _f(_password, 'পাসওয়ার্ড', obscure: true),
      ],
      if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12.5))),
      FilledButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_register ? 'অ্যাকাউন্ট তৈরি করুন' : 'লগইন করুন')),
      const SizedBox(height: 12),
      Center(child: TextButton(
        onPressed: () => setState(() { _register = !_register; _error = null; }),
        child: Text(_register ? 'আগে থেকে অ্যাকাউন্ট আছে? লগইন করুন' : 'অ্যাকাউন্ট নেই? রেজিস্টার করুন', style: TextStyle(color: brand, fontWeight: FontWeight.w700)),
      )),
    ]);
  }

  Widget _f(TextEditingController c, String label, {bool obscure = false, TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: c, obscureText: obscure, keyboardType: keyboard, decoration: InputDecoration(labelText: label)),
      );
}
