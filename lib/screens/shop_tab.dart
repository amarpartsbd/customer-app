import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';
import '../widgets/product_card.dart';

class ShopTab extends StatefulWidget {
  const ShopTab({super.key, this.categoryId, this.categoryName});
  final int? categoryId;
  final String? categoryName;
  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cats = [];
  int? _category;
  String _q = '';
  int _page = 1, _lastPage = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.categoryId;
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300 && !_loading && _page < _lastPage) _load();
    });
    _loadCats();
    _load(reset: true);
  }

  Future<void> _loadCats() async {
    if (widget.categoryId != null) return; // pushed category screen: no chips
    try {
      final d = await context.read<StoreState>().api.get('/categories');
      if (mounted) setState(() => _cats = (d['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {}
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    if (reset) { _page = 1; _products = []; }
    try {
      final d = await context.read<StoreState>().api.get('/products', query: {
        'page': _page,
        if (_category != null) 'category': _category,
        if (_q.isNotEmpty) 'q': _q,
      });
      final items = (d['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() {
        _products.addAll(items);
        _lastPage = (d['meta']?['last_page'] ?? 1) as int;
        _page++;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String v) { _q = v.trim(); _load(reset: true); }
  void _pickCat(int? id) { setState(() => _category = id); _load(reset: true); }

  @override
  Widget build(BuildContext context) {
    final pushed = widget.categoryId != null;
    return Scaffold(
      appBar: pushed
          ? AppBar(title: Text(widget.categoryName ?? 'পণ্য'))
          : null,
      body: SafeArea(
        top: !pushed,
        child: Column(children: [
          if (!pushed) Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'পণ্য খুঁজুন…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _q.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchCtrl.clear(); _search(''); }) : null,
              ),
            ),
          ),
          if (!pushed && _cats.isNotEmpty)
            SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              _chip('সব', _category == null, () => _pickCat(null)),
              for (final c in _cats) _chip(c['name'], _category == c['id'], () => _pickCat(c['id'] as int)),
            ])),
          Expanded(
            child: _products.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('কোনো পণ্য পাওয়া যায়নি।', style: TextStyle(color: kMuted)))
                    : GridView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.66),
                        itemCount: _products.length,
                        itemBuilder: (_, i) => ProductCard(product: _products[i]),
                      ),
          ),
          if (_loading && _products.isNotEmpty) const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) {
    final brand = context.read<StoreState>().brandColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? brand : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: sel ? brand : kLine),
            boxShadow: sel
                ? [BoxShadow(color: brand.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(color: sel ? Colors.white : kInk, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
