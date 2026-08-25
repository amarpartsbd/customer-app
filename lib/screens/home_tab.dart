import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';
import '../widgets/product_card.dart';
import 'shop_tab.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;
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
      onRefresh: () async => setState(() => _future = state.api.get('/home').then((d) => Map<String, dynamic>.from(d))),
      child: CustomScrollView(slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(gradient: brandGradient(brand)),
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if ((cfg['delivery_location'] ?? '').toString().isNotEmpty) ...[
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 15),
                  const SizedBox(width: 4),
                  Text(cfg['delivery_location'].toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
                const Spacer(),
                Text(state.storeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: widget.onSeeAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: Row(children: [
                    const Icon(Icons.search_rounded, color: kFaint, size: 20),
                    const SizedBox(width: 8),
                    Text(cfg['search_placeholder']?.toString() ?? 'পণ্য খুঁজুন…', style: const TextStyle(color: kFaint, fontSize: 13.5)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator())));
            }
            final data = snap.data ?? {};
            final hero = Map<String, dynamic>.from(data['hero'] ?? {});
            final sections = (data['sections'] as List?) ?? [];
            return SliverList.list(children: [
              // Hero
              if ((hero['title'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: brandGradient(brand), borderRadius: BorderRadius.circular(18)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(hero['title'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                      if ((hero['subtitle'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(hero['subtitle'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kInk, minimumSize: const Size(0, 42)), onPressed: widget.onSeeAll, child: const Text('এখনই কেনাকাটা করুন')),
                    ]),
                  ),
                ),
              for (final s in sections) _section(context, Map<String, dynamic>.from(s), state),
              const SizedBox(height: 24),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _section(BuildContext context, Map<String, dynamic> s, StoreState state) {
    final type = s['type'];
    if (type == 'categories') {
      final cats = (s['categories'] as List?) ?? [];
      if (cats.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(s['title'] ?? 'ক্যাটাগরি'),
        SizedBox(height: 96, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final c = Map<String, dynamic>.from(cats[i]);
            return GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShopTab(categoryId: c['id'] as int, categoryName: c['name']))),
              child: SizedBox(width: 72, child: Column(children: [
                Container(height: 64, width: 64, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)), clipBehavior: Clip.antiAlias,
                  child: c['image'] != null ? Image.network(c['image'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🛍️', style: TextStyle(fontSize: 26)))) : const Center(child: Text('🛍️', style: TextStyle(fontSize: 26)))),
                const SizedBox(height: 5),
                Text(c['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: kMuted)),
              ])),
            );
          },
        )),
      ]);
    }
    if (type == 'products') {
      final products = (s['products'] as List?) ?? [];
      if (products.isEmpty) return const SizedBox.shrink();
      final flash = s['flash'] == true;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(s['title'] ?? '', flash: flash, endsAt: flash ? context.read<StoreState>().config['flash_deal_ends_at']?.toString() : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.62),
            itemCount: products.length,
            itemBuilder: (_, i) => ProductCard(product: Map<String, dynamic>.from(products[i])),
          ),
        ),
      ]);
    }
    if (type == 'banner') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _hex(s['bg']?.toString() ?? '#16a34a'), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            if ((s['subtitle'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 4), Text(s['subtitle'], style: const TextStyle(color: Colors.white70))],
          ]),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _title(String text, {bool flash = false, String? endsAt}) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
        child: Row(children: [
          if (flash) const Text('⚡ ', style: TextStyle(fontSize: 16)),
          Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
          const Spacer(),
          if (flash && endsAt != null) _Countdown(endsAt: endsAt),
        ]),
      );

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
  Widget build(BuildContext context) => Text(_text, style: const TextStyle(color: kDanger, fontWeight: FontWeight.w800, fontSize: 13));
}
