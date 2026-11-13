import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../skin.dart';
import '../state/store_state.dart';
import '../widgets/nf_product_card.dart';

/// Home in the Nogor Farm look: logo + search, the animated hero (the website's phone layout),
/// round category tiles and every product in the website's card style.
class NfHome extends StatefulWidget {
  const NfHome({super.key, required this.onSearch, required this.onCart});
  final VoidCallback onSearch;
  final VoidCallback onCart;
  @override
  State<NfHome> createState() => _NfHomeState();
}

class _NfHomeState extends State<NfHome> {
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _cats = [];
  final List<Map<String, dynamic>> _products = [];
  int _page = 0, _last = 1, _total = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _more();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.read<StoreState>().api;
    try {
      final c = await api.get('/categories');
      _cats = (c['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {}
    _products.clear();
    _page = 0;
    _last = 1;
    await _more();
    if (mounted) setState(() {});
  }

  Future<void> _more() async {
    if (_loading || _page >= _last) return;
    _loading = true;
    try {
      final d = await context.read<StoreState>().api.get('/products', query: {'page': _page + 1});
      _products.addAll((d['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
      _page = (d['meta']?['current_page'] ?? _page + 1) as int;
      _last = (d['meta']?['last_page'] ?? _page) as int;
      _total = (d['meta']?['total'] ?? _products.length) as int;
    } catch (_) {
      _last = _page; // stop paging on error; pull to refresh retries
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final hero = state.config['skin_hero'] is Map ? Map<String, dynamic>.from(state.config['skin_hero']) : null;
    final w = MediaQuery.of(context).size.width;
    final cardW = (w - 16 * 2 - 10) / 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: Nf.bg,
        // White band behind the status bar so content never scrolls under the clock/icons.
        body: Column(children: [
          Container(height: MediaQuery.of(context).padding.top, color: Colors.white),
          Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: RefreshIndicator(
          color: Nf.green,
          onRefresh: _load,
          child: CustomScrollView(controller: _scroll, slivers: [
            SliverToBoxAdapter(child: _header(context, state)),
            if (hero != null)
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: NfHero(hero: hero))),
            if (_cats.isNotEmpty) ...[
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                child: Text('কী রান্না করবেন আজ?', style: Nf.t(20, w: FontWeight.w700)),
              )),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 14, crossAxisSpacing: 10, mainAxisExtent: 138),
                  delegate: SliverChildBuilderDelegate((_, i) => _RoundCat(cat: _cats[i]), childCount: _cats.length),
                ),
              ),
            ],
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Text('আমাদের সব পণ্য', style: Nf.t(20, w: FontWeight.w700))),
                if (_total > 0) Text('${bnDigits(_total)}টি পণ্য', style: Nf.t(13, color: Nf.muted2)),
              ]),
            )),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: NfProductCard.heightFor(cardW)),
                delegate: SliverChildBuilderDelegate((_, i) => NfProductCard(product: _products[i]), childCount: _products.length),
              ),
            ),
            if (_loading || _page < _last)
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Nf.green)))),
          ]),
        ))),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context, StoreState state) {
    final logo = state.config['logo']?.toString();
    const ph = 'খুঁজুন: Beef Boneless, দেশি হাঁস…';   // the website's own search hint
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(children: [
        Row(children: [
          if (logo != null) Image.network(logo, height: 44, errorBuilder: (_, _, _) => _name(state)) else _name(state),
          const Spacer(),
          if ((state.config['phone'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('হটলাইন\n${bnDigits(state.config['phone'])}', textAlign: TextAlign.right, style: Nf.t(11, color: Nf.muted2, height: 1.3)),
            ),
          Material(
            color: Nf.green,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onCart,
              child: SizedBox(width: 46, height: 46, child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
                if (state.cartCount > 0)
                  Positioned(right: 4, top: 4, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                    decoration: BoxDecoration(color: Nf.gold, borderRadius: BorderRadius.circular(9)),
                    alignment: Alignment.center,
                    child: Text(bnDigits(state.cartCount), style: Nf.t(10, w: FontWeight.w700, height: 1.2)),
                  )),
              ])),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        InkWell(
          onTap: widget.onSearch,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 46,
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(color: Nf.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Nf.line2)),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: Nf.muted2, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(ph, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nf.t(13.5, color: Nf.faint))),
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Nf.green, borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: Text('খুঁজুন', style: Nf.t(13, w: FontWeight.w600, color: Colors.white)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _name(StoreState s) => Text(s.storeName, style: Nf.t(18, w: FontWeight.w700, color: Nf.green));
}

/// Round category tile: the photo on a white plate with a pale-green halo, name below.
class _RoundCat extends StatelessWidget {
  const _RoundCat({required this.cat});
  final Map<String, dynamic> cat;

  @override
  Widget build(BuildContext context) {
    final img = cat['image']?.toString();
    final raw = (cat['name'] ?? '').toString();
    final name = raw.toUpperCase() == raw ? raw[0] + raw.substring(1).toLowerCase() : raw;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NfCategoryScreen(category: cat, title: name))),
      child: Column(children: [
        Container(
          width: 92, height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Nf.line2),
            boxShadow: const [
              BoxShadow(color: Nf.pill, spreadRadius: 5),
              BoxShadow(color: Color(0x1A10291F), blurRadius: 16, offset: Offset(0, 8), spreadRadius: 5),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: img != null ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()) : null,
        ),
        const SizedBox(height: 14),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: Nf.t(13, w: FontWeight.w600)),
      ]),
    );
  }
}

/// Products of one category, in the website's card style.
class NfCategoryScreen extends StatefulWidget {
  const NfCategoryScreen({super.key, required this.category, required this.title});
  final Map<String, dynamic> category;
  final String title;
  @override
  State<NfCategoryScreen> createState() => _NfCategoryScreenState();
}

class _NfCategoryScreenState extends State<NfCategoryScreen> {
  List<Map<String, dynamic>>? _products;

  @override
  void initState() {
    super.initState();
    context.read<StoreState>().api.get('/products', query: {'category': widget.category['id']}).then((d) {
      if (mounted) setState(() => _products = (d['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList());
    }).catchError((_) {
      if (mounted) setState(() => _products = []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = (w - 16 * 2 - 10) / 2;
    return Scaffold(
      backgroundColor: Nf.bg,
      appBar: AppBar(backgroundColor: Colors.white, title: Text(widget.title, style: Nf.t(18, w: FontWeight.w700))),
      body: _products == null
          ? const Center(child: CircularProgressIndicator(color: Nf.green))
          : _products!.isEmpty
              ? Center(child: Text('কোনো পণ্য পাওয়া যায়নি', style: Nf.t(14, color: Nf.muted)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: NfProductCard.heightFor(cardW)),
                  itemCount: _products!.length,
                  itemBuilder: (_, i) => NfProductCard(product: _products![i]),
                ),
    );
  }
}

/// The website's animated hero, phone layout (360×400 design scaled to the width): caption,
/// gold underline and points rise in; the product cut-outs glide in then float; the dashed
/// ring turns. Static when the phone has animations turned off.
class NfHero extends StatefulWidget {
  const NfHero({super.key, required this.hero});
  final Map<String, dynamic> hero;
  @override
  State<NfHero> createState() => _NfHeroState();
}

class _NfHeroState extends State<NfHero> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 7));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _in.value = 1;
      _loop.stop();
    } else if (!_in.isAnimating && _in.value == 0) {
      _in.forward();
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// 0→1 progress of a part that starts at [from] s and lasts [dur] s within the entrance.
  double _part(double from, double dur) {
    final t = _in.value * 1.9;
    return Curves.easeOutCubic.transform(((t - from) / dur).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hero;
    final title = (h['title'] as List? ?? const ['', '']).map((e) => e.toString()).toList();
    final chips = (h['chips'] as List? ?? const []).map((e) => e.toString()).toList();
    final images = h['images'] is Map ? Map<String, dynamic>.from(h['images']) : <String, dynamic>{};

    return LayoutBuilder(builder: (context, c) {
      final W = c.maxWidth;
      final H = W * 400 / 360;
      double cq(double v) => W * v / 100; // like CSS cqw

      // product cut-outs: left%, top%, width%, entrance delay (s), float period (s)
      const parts = [
        ['chicken', 30.56, 46.25, 38.9, .25, 7.0],
        ['oil', 74.4, 60.0, 27.8, .5, 8.0],
        ['beef', 2.8, 59.25, 41.7, .4, 6.0],
        ['duck', 53.6, 63.75, 41.7, .6, 6.6],
        ['mutton', 31.9, 71.25, 36.1, .75, 7.4],
      ];

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: W,
          height: H,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Nf.line2),
            gradient: const LinearGradient(colors: [Color(0xFFFBF8EF), Color(0xFFF7F6EE), Color(0xFFEEF4EA)], stops: [0, .55, 1]),
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([_in, _loop]),
            builder: (context, _) => Stack(clipBehavior: Clip.none, children: [
              // glow, plate, turning dashed ring
              Positioned(left: W * .056, top: H * .35, width: W * .889, height: W * .889, child: const DecoratedBox(decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x4DF5B81F), Color(0x1FF5B81F), Color(0x00F5B81F)], stops: [0, .55, 1]),
              ))),
              Positioned(left: W * .244, top: H * .52, width: W * .511, height: W * .511, child: Opacity(
                opacity: _part(.05, 1),
                child: Transform.scale(scale: .85 + .15 * _part(.05, 1), child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xD9E7EFE5)))),
              )),
              Positioned(left: W * .208, top: H * .4875, width: W * .583, height: W * .583, child: Opacity(
                opacity: _part(.3, .8),
                child: Transform.rotate(angle: _loop.value * 2 * math.pi / 8.57, child: CustomPaint(painter: _DashedRing())),
              )),
              // products
              for (final p in parts)
                if (images[p[0]] != null)
                  Positioned(
                    left: W * (p[1] as double) / 100,
                    top: H * (p[2] as double) / 100,
                    width: W * (p[3] as double) / 100,
                    child: Builder(builder: (_) {
                      final e = _part(p[4] as double, .95);
                      final period = p[5] as double;
                      final f = math.sin(_loop.value * 2 * math.pi * 7 / period + (p[4] as double) * 3); // gentle float
                      return Opacity(
                        opacity: e,
                        child: Transform.translate(
                          offset: Offset(0, (1 - e) * cq(6) + f * cq(1.1) * e),
                          child: Image.network(images[p[0]].toString(), fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
                        ),
                      );
                    }),
                  ),
              // caption
              Positioned(
                left: W * .06, top: H * .06, width: W * .88,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _rise(0, Container(
                    height: cq(7.4),
                    padding: EdgeInsets.only(left: cq(2.8), right: cq(3.6)),
                    decoration: BoxDecoration(color: Nf.green, borderRadius: BorderRadius.circular(99)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: cq(2), height: cq(2), decoration: const BoxDecoration(color: Nf.gold, shape: BoxShape.circle)),
                      SizedBox(width: cq(1.8)),
                      Text((h['pill'] ?? '').toString(), style: Nf.t(cq(3.4), color: Colors.white, height: 1.1)),
                    ]),
                  )),
                  SizedBox(height: cq(3.6)),
                  _rise(.12, Text(title.isNotEmpty ? title[0] : '', style: Nf.t(cq(7.9), w: FontWeight.w700, height: 1.22))),
                  _rise(.24, Stack(children: [
                    Positioned(
                      left: cq(.6), bottom: 0, height: cq(1.9),
                      width: (_textWidth(title.length > 1 ? title[1] : '', Nf.t(cq(7.9), w: FontWeight.w700)) - cq(.6)) * _part(.95, .85),
                      child: DecoratedBox(decoration: BoxDecoration(color: Nf.gold.withValues(alpha: .92), borderRadius: BorderRadius.circular(99))),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: cq(.9)),
                      child: Text(title.length > 1 ? title[1] : '', style: Nf.t(cq(7.9), w: FontWeight.w700, color: Nf.green, height: 1.22)),
                    ),
                  ])),
                  SizedBox(height: cq(4)),
                  Wrap(spacing: cq(1.8), runSpacing: cq(1.8), children: [
                    for (var i = 0; i < chips.length; i++)
                      Opacity(
                        opacity: _part(.85 + i * .12, .55),
                        child: Transform.scale(
                          scale: .7 + .3 * Curves.easeOutBack.transform(_part(.85 + i * .12, .55)),
                          child: Container(
                            height: cq(7.6),
                            padding: EdgeInsets.only(left: cq(1.6), right: cq(3)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: const Color(0x2414532D)),
                              boxShadow: const [BoxShadow(color: Color(0x1A10291F), blurRadius: 9, offset: Offset(0, 3))],
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: cq(4.3), height: cq(4.3),
                                decoration: const BoxDecoration(color: Nf.green, shape: BoxShape.circle),
                                child: Icon(Icons.check_rounded, size: cq(3.2), color: Colors.white),
                              ),
                              SizedBox(width: cq(1.6)),
                              Text(chips[i], style: Nf.t(cq(3.15), height: 1.1)),
                            ]),
                          ),
                        ),
                      ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _rise(double from, Widget child) {
    final e = _part(from, .75);
    return Opacity(opacity: e, child: Transform.translate(offset: Offset(0, (1 - e) * 14), child: child));
  }

  double _textWidth(String s, TextStyle st) {
    final tp = TextPainter(text: TextSpan(text: s, style: st), textDirection: TextDirection.ltr, maxLines: 1)..layout();
    return tp.width;
  }
}

class _DashedRing extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xCCD69E14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r = size.width / 2;
    const dashes = 64;
    for (var i = 0; i < dashes; i++) {
      final a = i * 2 * math.pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: Offset(r, r), radius: r - 1), a, math.pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
