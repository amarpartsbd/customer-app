import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../skin.dart';
import '../state/store_state.dart';

/// "ডেলিভারি এলাকা যাচাই করুন" — the website's delivery-area check as a bottom sheet.
/// Calls POST /delivery/check and shows available / unavailable / unverified. On "available",
/// [onOrderNow] gets the confirmed address (the product page adds the item and opens checkout).
class NfDeliveryCheckSheet extends StatefulWidget {
  const NfDeliveryCheckSheet({super.key, required this.productId, required this.onOrderNow});
  final int productId;
  final void Function(String address) onOrderNow;

  /// Opens the sheet.
  static Future<void> show(BuildContext context, {required int productId, required void Function(String address) onOrderNow}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => NfDeliveryCheckSheet(productId: productId, onOrderNow: onOrderNow),
    );
  }

  @override
  State<NfDeliveryCheckSheet> createState() => _NfDeliveryCheckSheetState();
}

class _NfDeliveryCheckSheetState extends State<NfDeliveryCheckSheet> {
  final _addr = TextEditingController();
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _addr.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final a = _addr.text.trim();
    if (a.length < 6) {
      setState(() => _error = 'আরও বিস্তারিত ঠিকানা লিখুন (বাসা, রোড, এলাকা, থানা, জেলা)।');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await context.read<StoreState>().api.post('/delivery/check', body: {'address': a, 'product_id': widget.productId});
      if (mounted) setState(() => _result = Map<String, dynamic>.from(d));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.statusCode == 429 ? 'অনেকবার চেষ্টা করা হয়েছে — এক মিনিট পরে আবার চেষ্টা করুন।' : e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: _result == null ? _form() : _resultView(_result!),
      ),
    );
  }

  Widget _form() => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Nf.line2, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        Text('ডেলিভারি পাওয়া যাবে কি না যাচাই করুন', style: Nf.t(20, w: FontWeight.w700, height: 1.3)),
        const SizedBox(height: 6),
        Text('এই পণ্যটি আপনার এলাকায় ডেলিভারি পাওয়া যাবে কি না জানতে আপনার পূর্ণ ঠিকানা লিখুন।', style: Nf.t(14, color: Nf.muted2, height: 1.5)),
        const SizedBox(height: 14),
        Text('আপনার ঠিকানা', style: Nf.t(14, w: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _addr,
          autofocus: true,
          minLines: 3,
          maxLines: 4,
          maxLength: 500,
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.newline,
          style: Nf.t(15),
          decoration: InputDecoration(
            hintText: 'পূর্ণ ঠিকানা লিখুন (বাসা, রোড, এলাকা, থানা, জেলা)',
            hintStyle: Nf.t(14, color: Nf.faint),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Nf.line2, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Nf.green, width: 1.5)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: Nf.t(13.5, color: Nf.red)),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Nf.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _busy ? null : _check,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text('যাচাই করুন', style: Nf.t(17, w: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ]);

  Widget _resultView(Map<String, dynamic> r) {
    final status = r['status']?.toString();
    final ok = status == 'available';
    final no = status == 'unavailable';
    final color = ok ? const Color(0xFF16A34A) : (no ? Nf.red : const Color(0xFFB7791F));
    final icon = ok ? Icons.check_rounded : (no ? Icons.close_rounded : Icons.question_mark_rounded);

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 10),
      Center(child: Semantics(
        label: ok ? 'ডেলিভারি পাওয়া যাবে' : (no ? 'ডেলিভারি পাওয়া যাবে না' : 'যাচাই করা যায়নি'),
        child: Container(width: 64, height: 64, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 36)),
      )),
      const SizedBox(height: 12),
      Text((r['title'] ?? '').toString(), textAlign: TextAlign.center, style: Nf.t(20, w: FontWeight.w700, color: ok ? const Color(0xFF15803D) : (no ? Nf.red : const Color(0xFF975A16)))),
      const SizedBox(height: 6),
      Text((r['message'] ?? '').toString(), textAlign: TextAlign.center, style: Nf.t(14, color: Nf.muted2, height: 1.5)),
      const SizedBox(height: 16),
      if (ok)
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              final a = _addr.text.trim();
              Navigator.of(context).pop();
              widget.onOrderNow(a);
            },
            child: Text('এখনই অর্ডার করুন', style: Nf.t(17, w: FontWeight.w600, color: Colors.white)),
          ),
        )
      else
        SizedBox(
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Nf.green, width: 1.5), foregroundColor: Nf.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => setState(() => _result = null),
            child: Text('অন্য ঠিকানা দিন', style: Nf.t(15, w: FontWeight.w600, color: Nf.green)),
          ),
        ),
    ]);
  }
}
