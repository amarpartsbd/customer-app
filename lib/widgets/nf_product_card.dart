import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/product_screen.dart';
import '../skin.dart';
import '../state/store_state.dart';
import 'animated_money.dart';

/// Product card in the Nogor Farm look — mirrors the website's card: photo with the gold
/// discount stamp (and the "A product of …" label for chicken), English name + Bangla name,
/// ±50 g tag for weight items, red price that rolls when the amount changes, the amount
/// chooser (500 g / 1 kg / 2 kg or the admin's own options) and "ব্যাগে যোগ করুন".
class NfProductCard extends StatefulWidget {
  const NfProductCard({super.key, required this.product, this.onAdded});
  final Map<String, dynamic> product;
  final VoidCallback? onAdded;

  /// Card height for a given card width (grids use a fixed extent so cards line up).
  static double heightFor(double width) => width * 0.75 + 218;

  @override
  State<NfProductCard> createState() => _NfProductCardState();
}

class _NfProductCardState extends State<NfProductCard> {
  late List<Map<String, dynamic>> _presets;
  late num _qty;

  Map<String, dynamic> get p => widget.product;

  @override
  void initState() {
    super.initState();
    _presets = (p['presets'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e)).toList();
    _qty = StoreState.defaultQtyOf(p);
    if (_presets.isNotEmpty && !_presets.any((o) => ((o['qty'] as num) - _qty).abs() < 0.0005)) {
      _qty = _presets.first['qty'] as num;
    }
  }

  void _open() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(productId: p['id'] as int)));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();

    final price = StoreState.priceFor(p, _qty);
    final cmp = StoreState.compareFor(p, _qty);
    final pct = (p['discount_percent'] ?? 0) as int;
    final img = p['image']?.toString();
    final nameEn = (p['name_en'] ?? p['name'] ?? '').toString();
    final nameBn = (p['name_bn'] ?? '').toString();
    final weight = p['sold_by_weight'] == true;
    final maker = p['maker']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Nf.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Photo
        AspectRatio(
          aspectRatio: 4 / 3,
          child: InkWell(
            onTap: _open,
            child: Stack(children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: img != null
                      ? Image.network(img, fit: BoxFit.contain, errorBuilder: (_, _, _) => _noImg())
                      : _noImg(),
                ),
              ),
              if (pct > 0)
                Positioned(right: 6, top: 6, child: Container(
                  width: 46, height: 46,
                  decoration: const BoxDecoration(color: Nf.gold, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${bnDigits(pct)}%', style: Nf.t(14, w: FontWeight.w700, height: 1)),
                    Text('ছাড়', style: Nf.t(10, w: FontWeight.w600, height: 1.1)),
                  ]),
                )),
              if (maker != null)
                Positioned(left: 0, right: 0, bottom: 4, child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(9), border: Border.all(color: Nf.line)),
                  child: Text.rich(TextSpan(style: Nf.t(9, color: Nf.muted2), children: [
                    const TextSpan(text: 'A product of '),
                    TextSpan(text: maker, style: const TextStyle(fontWeight: FontWeight.w700, color: Nf.green)),
                  ]), maxLines: 1, overflow: TextOverflow.ellipsis),
                ))),
            ]),
          ),
        ),
        // Body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              InkWell(
                onTap: _open,
                child: Text(nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nf.t(14, w: FontWeight.w600, height: 1.3)),
              ),
              const SizedBox(height: 2),
              Row(children: [
                Expanded(child: Text(nameBn, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nf.t(12, color: Nf.muted, height: 1.4))),
                if (weight)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Nf.pill, borderRadius: BorderRadius.circular(10)),
                    child: Text('± ৫০ গ্রাম', style: Nf.t(10, w: FontWeight.w600, color: Nf.green, height: 1.2)),
                  ),
              ]),
              const SizedBox(height: 6),
              // Price (rolls when the amount changes) + old price
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                AnimatedMoney(price, style: Nf.t(20, w: FontWeight.w700, color: Nf.red, height: 1.1)),
                const SizedBox(width: 4),
                Flexible(child: Text('/ ${bnQty(_qty, p)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nf.t(11.5, color: Nf.muted2))),
              ]),
              SizedBox(
                height: 16,
                child: cmp > 0
                    ? AnimatedMoney(cmp, style: Nf.t(12, color: Nf.faint, deco: TextDecoration.lineThrough))
                    : null,
              ),
              const Spacer(),
              if (_presets.isNotEmpty) _chooser(),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Nf.green,
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    state.addToCart(p, _qty);
                    widget.onAdded?.call();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text('${bnQty(_qty, p)} $nameEn ব্যাগে যোগ হয়েছে', style: Nf.t(13, color: Colors.white)),
                        duration: const Duration(seconds: 2),
                      ));
                  },
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.shopping_bag_outlined, size: 17),
                    const SizedBox(width: 6),
                    Flexible(child: Text('ব্যাগে যোগ করুন', maxLines: 1, overflow: TextOverflow.ellipsis, style: Nf.t(13.5, w: FontWeight.w600, color: Colors.white))),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  /// Segmented amount chooser, like the website: the chosen amount gets a pale gold fill
  /// with a gold underline.
  Widget _chooser() {
    final shown = _presets.take(4).toList();
    return Container(
      height: 34,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Nf.line2, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: Row(children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const VerticalDivider(width: 1.5, thickness: 1.5, color: Nf.line2),
          Expanded(child: _seg(shown[i], shown.length)),
        ],
      ]),
    );
  }

  Widget _seg(Map<String, dynamic> o, int n) {
    final q = o['qty'] as num;
    final on = (q - _qty).abs() < 0.0005;
    return Semantics(
      selected: on,
      button: true,
      child: InkWell(
        onTap: () => setState(() => _qty = q),
        child: Container(
          alignment: Alignment.center,
          decoration: on
              ? const BoxDecoration(color: Nf.sel, border: Border(bottom: BorderSide(color: Nf.gold, width: 3)))
              : null,
          child: Text(
            (o['label'] ?? bnQty(q, p)).toString(),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Nf.t(n >= 4 ? 10.5 : 12, w: on ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ),
    );
  }

  Widget _noImg() => Center(child: Text('ছবি নেই', style: Nf.t(12, color: Nf.muted)));
}
