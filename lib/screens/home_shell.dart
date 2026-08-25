import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import 'home_tab.dart';
import 'shop_tab.dart';
import 'cart_tab.dart';
import 'account_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    final brand = state.brandColor;
    final pages = [HomeTab(onSeeAll: () => goTo(1), onCart: () => goTo(2)), const ShopTab(), const CartTab(), const AccountTab()];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goTo,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'হোম'),
          const NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'শপ'),
          NavigationDestination(
            icon: _CartIcon(count: state.cartCount, brand: brand, filled: false),
            selectedIcon: _CartIcon(count: state.cartCount, brand: brand, filled: true),
            label: 'কার্ট',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'অ্যাকাউন্ট'),
        ],
      ),
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, required this.brand, required this.filled});
  final int count;
  final Color brand;
  final bool filled;
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Icon(filled ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined),
        if (count > 0)
          Positioned(right: -8, top: -6, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 1.5)),
            child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          )),
      ]);
}
