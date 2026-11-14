import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../skin.dart';
import '../state/store_state.dart';
import '../widgets/animated_money.dart';
import '../widgets/nf_product_card.dart';
import '../widgets/nf_delivery_check.dart';
import 'checkout_screen.dart';

/// Product page in the Nogor Farm look — the website's product page on a phone.
class NfProductView extends StatefulWidget {
  const NfProductView({super.key, required this.product, required this.related});
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> related;
  @override
  State<NfProductView> createState() => _NfProductViewState();
}

class _NfProductViewState extends State<NfProductView> {
  late num _qty;
  Map<String, dynamic> get p => widget.product;

  @override
  void initState() {
    super.initState();
    _qty = StoreState.defaultQtyOf(p);
  }

  void _set(num q) {
    final min = StoreState.minOf(p);
    final weight = p['sold_by_weight'] == true;
    final v = (weight ? (q * 1000).round() / 1000 : q.round()).clamp(min, 999);
    setState(() => _qty = v);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final cfg = state.config;
    final price = StoreState.priceFor(p, _qty);
    final cmp = StoreState.compareFor(p, _qty);
    final presets = (p['presets'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e)).toList();
    final weight = p['sold_by_weight'] == true;
    final step = StoreState.stepOf(p);
    final img = p['image']?.toString();
    final phone = (cfg['phone'] ?? '').toString();
    final tolerance = (cfg['skin_hero'] is Map ? cfg['skin_hero']['tolerance'] : null)?.toString() ?? 'কাটার পর ওজনে ±৫০ গ্রাম তারতম্য হতে পারে।';
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Nf.bg,
      appBar: AppBar(backgroundColor: Colors.white, title: Text((p['category'] ?? '').toString(), style: Nf.t(16, w: FontWeight.w600))),
      bottomNavigationBar: SafeArea(child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Nf.line))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
        // "Check delivery area" — right above "add to bag" (stores with delivery areas switched on).
        if (cfg['delivery_check'] == true) ...[
          SizedBox(
            height: 44,
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Nf.pill,
                foregroundColor: Nf.green,
                side: const BorderSide(color: Nf.green, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => NfDeliveryCheckSheet.show(context, productId: p['id'] as int, onOrderNow: (address) {
                // Order now: the chosen amount into the bag, then checkout with the confirmed address.
                state.addToCart(p, _qty);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutScreen(initialAddress: address)));
              }),
              icon: const Icon(Icons.location_on_outlined, size: 19),
              label: Text('ডেলিভারি এলাকা যাচাই করুন', style: Nf.t(14.5, w: FontWeight.w600, color: Nf.green)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Nf.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              state.addToCart(p, _qty);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('${bnQty(_qty, p)} ব্যাগে যোগ হয়েছে', style: Nf.t(13, color: Colors.white)), duration: const Duration(seconds: 2)));
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.shopping_bag_outlined, size: 20),
              const SizedBox(width: 8),
              Text('ব্যাগে যোগ করুন', style: Nf.t(16, w: FontWeight.w600, color: Colors.white)),
              Text('  •  ', style: Nf.t(16, color: Colors.white70)),
              AnimatedMoney(price, style: Nf.t(16, w: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
        ]),
      )),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        // Photo
        Container(
          height: w - 32,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Nf.line)),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned.fill(child: Padding(
              padding: const EdgeInsets.all(16),
              child: img != null ? Image.network(img, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()) : Center(child: Text('[পণ্যের ছবি]', style: Nf.t(14, color: Nf.muted))),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        Text((p['name'] ?? '').toString(), style: Nf.t(24, w: FontWeight.w700, height: 1.2)),
        const SizedBox(height: 6),
        Row(children: [
          if ((p['category'] ?? '').toString().isNotEmpty) Text(p['category'].toString(), style: Nf.t(13, color: Nf.muted)),
          if (weight) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: Nf.pill, borderRadius: BorderRadius.circular(11)),
              child: Text('± ৫০ গ্রাম', style: Nf.t(12, w: FontWeight.w600, color: Nf.green)),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        // Price (rolls when the amount changes), old price and saving
        Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 8, runSpacing: 2, children: [
          AnimatedMoney(price, style: Nf.t(38, w: FontWeight.w700, color: Nf.red, height: 1.1)),
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('/ ${bnQty(_qty, p)}', style: Nf.t(14, color: Nf.muted2))),
          if (cmp > 0) ...[
            Padding(padding: const EdgeInsets.only(bottom: 6), child: AnimatedMoney(cmp, style: Nf.t(14, color: const Color(0xFF56665C), deco: TextDecoration.lineThrough))),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                AnimatedMoney(cmp - price, style: Nf.t(20, w: FontWeight.w700, color: Nf.green)),
                const SizedBox(width: 4),
                Text('সাশ্রয়', style: Nf.t(13, color: Nf.muted2)),
              ]),
            ),
          ],
        ]),
        const SizedBox(height: 18),
        Text('কতটুকু লাগবে?', style: Nf.t(16, w: FontWeight.w600)),
        const SizedBox(height: 10),
        if (presets.isNotEmpty)
          GridView.count(
            crossAxisCount: presets.length >= 4 ? 4 : presets.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: presets.length >= 4 ? 1.25 : 1.9,
            children: [for (final o in presets.take(8)) _preset(o)],
          ),
        const SizedBox(height: 10),
        // − amount +
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Nf.line2)),
          child: Row(children: [
            _stepBtn(Icons.remove_rounded, Nf.pill, Nf.ink, () => _set(_qty - step)),
            Expanded(child: Column(children: [
              Text(bnQty(_qty, p), style: Nf.t(17, w: FontWeight.w700)),
              Text('পরিমাণ বাড়াতে/কমাতে + বা − চাপুন', style: Nf.t(11, color: Nf.muted2)),
            ])),
            _stepBtn(Icons.add_rounded, Nf.green, Colors.white, () => _set(_qty + step)),
          ]),
        ),
        if (weight) ...[
          const SizedBox(height: 8),
          Text(tolerance, style: Nf.t(12, color: Nf.muted2)),
        ],
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Nf.green), foregroundColor: Nf.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => launchUrl(Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}')),
              icon: const Icon(Icons.call_outlined, size: 18),
              label: Text('কল করে অর্ডার দিন: ${bnDigits(phone)}', style: Nf.t(14, w: FontWeight.w600, color: Nf.green)),
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Delivery info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Nf.line)),
          child: Column(children: [
            _info('ডেলিভারি', (cfg['delivery_location'] ?? 'ঢাকা সিটি').toString() + ' • ২৪–৪৮ ঘণ্টায়'),
            const Divider(height: 1, color: Nf.line),
            _info('ডেলিভারি চার্জ', state.fmt((cfg['delivery_charge'] ?? 0) as num)),
            const Divider(height: 1, color: Nf.line),
            _info('পেমেন্ট', cfg['online_payment_enabled'] == true ? 'ক্যাশ অন ডেলিভারি / অনলাইন' : 'ক্যাশ অন ডেলিভারি'),
          ]),
        ),
        if ((p['description'] ?? '').toString().trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('পণ্যের বিবরণ', style: Nf.t(17, w: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(p['description'].toString(), style: Nf.t(14, color: Nf.muted2, height: 1.6)),
        ],
        if (widget.related.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('এগুলোও দেখতে পারেন', style: Nf.t(19, w: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: NfProductCard.heightFor(170),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.related.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(width: 170, child: NfProductCard(product: widget.related[i])),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _preset(Map<String, dynamic> o) {
    final q = o['qty'] as num;
    final on = (q - _qty).abs() < 0.0005;
    return Semantics(
      selected: on,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _qty = q),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: on ? Nf.sel : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? Nf.ink : Nf.line2, width: on ? 1.5 : 1),
          ),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text((o['label'] ?? bnQty(q, p)).toString(), style: Nf.t(13.5, w: on ? FontWeight.w600 : FontWeight.w500)),
            Text(context.read<StoreState>().fmt((o['price'] ?? 0) as num), style: Nf.t(12, w: FontWeight.w600, color: Nf.red)),
          ]),
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) => Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap, child: SizedBox(width: 46, height: 46, child: Icon(icon, color: fg))),
      );

  Widget _info(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(children: [
          Text(k, style: Nf.t(13.5, color: Nf.muted2)),
          const SizedBox(width: 10),
          Expanded(child: Text(v, textAlign: TextAlign.right, style: Nf.t(13.5, w: FontWeight.w600))),
        ]),
      );
}
