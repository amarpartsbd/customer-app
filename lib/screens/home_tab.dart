import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';
import '../widgets/product_card.dart';
import 'shop_tab.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onSeeAll, required this.onCart});
  final VoidCallback onSeeAll;
  final VoidCallback onCart;
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<StoreState>().api.get('/home').then((d) => Map<String, dynamic>.from(d));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final brand = state.brandColor;
    final cfg = state.config;

    return RefreshIndicator(
      color: brand,
      onRefresh: () async => setState(() => _future = state.api.get('/home').then((d) => Map<String, dynamic>.from(d))),
      child: CustomScrollView(slivers: [
        // ── Header (brand gradient → white status-bar icons) ────
        SliverToBoxAdapter(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            child: Container(
            decoration: BoxDecoration(
              gradient: brandGradient(brand),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_greeting()} 👋', style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(state.storeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: -0.2)),
                  ]),
                ),
                _circleBtn(Icons.notifications_none_rounded, () {}),
                const SizedBox(width: 10),
                _circleBtn(Icons.shopping_bag_outlined, widget.onCart, badge: state.cartCount),
              ]),
              if ((cfg['delivery_location'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 15),
                  const SizedBox(width: 4),
                  Text('ডেলিভারি: ${cfg['delivery_location']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: widget.onSeeAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: kCardShadow),
                  child: Row(children: [
                    Icon(Icons.search_rounded, color: brand, size: 21),
                    const SizedBox(width: 10),
                    Expanded(child: Text(cfg['search_placeholder']?.toString() ?? 'পণ্য খুঁজুন…', style: const TextStyle(color: kFaint, fontSize: 13.5))),
                    Icon(Icons.tune_rounded, color: kFaint, size: 19),
                  ]),
                ),
              ),
            ]),
          ),
          ),
        ),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 90), child: Center(child: CircularProgressIndicator(color: brand))));
            }
            final data = snap.data ?? {};
            final hero = Map<String, dynamic>.from(data['hero'] ?? {});
            final banners = ((hero['banners'] as List?) ?? []).map((b) => Map<String, dynamic>.from(b)).toList();
            final sections = (data['sections'] as List?) ?? [];
            return SliverList.list(children: [
              if (banners.isNotEmpty)
                _BannerCarousel(banners: banners)
              else if ((hero['title'] ?? '').toString().isNotEmpty)
                _hero(hero, brand),
              for (final s in sections) _section(context, Map<String, dynamic>.from(s), state),
              const SizedBox(height: 26),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _hero(Map<String, dynamic> hero, Color brand) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: brandGradient(brand), borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hero['title'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.15)),
                if ((hero['subtitle'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(hero['subtitle'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: brand, minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: widget.onSeeAll,
                  child: const Text('এখনই কেনাকাটা', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            const Text('🛒', style: TextStyle(fontSize: 60)),
          ]),
        ),
      );

  Widget _section(BuildContext context, Map<String, dynamic> s, StoreState state) {
    final type = s['type'];
    if (type == 'categories') {
      final cats = (s['categories'] as List?) ?? [];
      if (cats.isEmpty) return const SizedBox.shrink();
      final brand = state.brandColor;
      final shown = cats.take(6).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(s['title'] ?? 'ক্যাটাগরি', onSeeAll: widget.onSeeAll),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.9),
            itemCount: shown.length,
            itemBuilder: (_, i) {
              final c = Map<String, dynamic>.from(shown[i]);
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShopTab(categoryId: c['id'] as int, categoryName: c['name']))),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine), boxShadow: kCardShadow),
                  padding: const EdgeInsets.all(8),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      height: 56, width: 56,
                      decoration: BoxDecoration(color: brandTint(brand, 0.10), borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(6),
                      child: c['image'] != null
                          ? Image.network(c['image'], fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Text('🥗', style: TextStyle(fontSize: 26, color: brand))))
                          : const Center(child: Text('🥗', style: TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(height: 8),
                    Text(c['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: kInk, fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]);
    }
    if (type == 'products') {
      final products = (s['products'] as List?) ?? [];
      if (products.isEmpty) return const SizedBox.shrink();
      final flash = s['flash'] == true;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(s['title'] ?? '', flash: flash, endsAt: flash ? state.config['flash_deal_ends_at']?.toString() : null, onSeeAll: widget.onSeeAll),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.66),
            itemCount: products.length,
            itemBuilder: (_, i) => ProductCard(product: Map<String, dynamic>.from(products[i])),
          ),
        ),
      ]);
    }
    if (type == 'banner') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _hex(s['bg']?.toString() ?? '#16a34a'), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            if ((s['subtitle'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 4), Text(s['subtitle'], style: const TextStyle(color: Colors.white70))],
          ]),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _title(String text, {bool flash = false, String? endsAt, VoidCallback? onSeeAll}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
        child: Row(children: [
          if (flash) const Text('⚡ ', style: TextStyle(fontSize: 17)),
          Text(text, style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: kInk, letterSpacing: -0.2)),
          const Spacer(),
          if (flash && endsAt != null)
            _Countdown(endsAt: endsAt)
          else if (onSeeAll != null)
            GestureDetector(onTap: onSeeAll, child: Text('সব দেখুন', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.read<StoreState>().brandColor))),
        ]),
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap, {int badge = 0}) => GestureDetector(
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            height: 42, width: 42,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge > 0)
            Positioned(right: -4, top: -4, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 1.5)),
              child: Text('$badge', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            )),
        ]),
      );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'সুপ্রভাত';
    if (h < 17) return 'শুভ অপরাহ্ন';
    return 'শুভ সন্ধ্যা';
  }

  Color _hex(String h) => (h.startsWith('#') && h.length == 7) ? Color(int.parse('FF${h.substring(1)}', radix: 16)) : const Color(0xFF16A34A);
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.endsAt});
  final String endsAt;
  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late DateTime _ends;
  String _text = '';
  @override
  void initState() {
    super.initState();
    _ends = DateTime.tryParse(widget.endsAt) ?? DateTime.now();
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    var s = _ends.difference(DateTime.now()).inSeconds;
    if (s < 0) s = 0;
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    setState(() => _text = '${_p(h)}:${_p(m)}:${_p(sec)}');
    Future.delayed(const Duration(seconds: 1), _tick);
  }

  String _p(int n) => n.toString().padLeft(2, '0');
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: kDanger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(_text, style: const TextStyle(color: kDanger, fontWeight: FontWeight.w800, fontSize: 12.5)),
      );
}

/// Swipeable, auto-scrolling promo banners (same images as the website hero).
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners});
  final List<Map<String, dynamic>> banners;
  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_page + 1) % widget.banners.length;
        _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.read<StoreState>().brandColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: [
        AspectRatio(
          aspectRatio: 16 / 8,
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: kCardShadow),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: widget.banners.length,
                itemBuilder: (_, i) {
                  final img = widget.banners[i]['image']?.toString();
                  if (img == null) return const ColoredBox(color: Color(0xFFEBEFEA));
                  return Image.network(img, fit: BoxFit.cover,
                      loadingBuilder: (c, w, p) => p == null ? w : const ColoredBox(color: Color(0xFFF1F5F4)),
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEBEFEA)));
                },
              ),
            ),
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < widget.banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: _page == i ? 18 : 6,
                decoration: BoxDecoration(
                  color: _page == i ? brand : kFaint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ]),
        ],
      ]),
    );
  }
}
