import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/providers/product_provider.dart';
import 'package:boutique_manager/providers/order_provider.dart';
import 'package:boutique_manager/providers/settings_provider.dart';
import 'package:boutique_manager/screens/owner_dashboard_screen.dart';
import 'package:boutique_manager/screens/inventory_screen.dart';
import 'package:boutique_manager/screens/ledger_screen.dart';
import 'package:boutique_manager/screens/visual_search_screen.dart';
import 'package:boutique_manager/screens/settings_screen.dart';
import 'package:boutique_manager/screens/client_browse_screen.dart';
import 'package:boutique_manager/screens/orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return settings.isOwner
        ? _OwnerHome(
            currentIndex: _currentIndex,
            onIndexChanged: (i) => setState(() => _currentIndex = i),
          )
        : _ClientHome(
            currentIndex: _currentIndex,
            onIndexChanged: (i) => setState(() => _currentIndex = i),
          );
  }
}

class _OwnerHome extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _OwnerHome({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    final screens = const [
      OwnerDashboardScreen(),
      InventoryScreen(),
      LedgerScreen(),
      VisualSearchScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onIndexChanged,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: productProvider.lowStockProducts.isNotEmpty,
              label: Text('${productProvider.lowStockProducts.length}'),
              child: const Icon(Icons.inventory_2_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: productProvider.lowStockProducts.isNotEmpty,
              label: Text('${productProvider.lowStockProducts.length}'),
              child: const Icon(Icons.inventory_2),
            ),
            label: 'Inventory',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Ledger',
          ),
          const NavigationDestination(
            icon: Icon(Icons.image_search_outlined),
            selectedIcon: Icon(Icons.image_search),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _ClientHome extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _ClientHome({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final screens = const [
      ClientBrowseScreen(),
      VisualSearchScreen(),
      OrdersScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onIndexChanged,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Browse',
          ),
          const NavigationDestination(
            icon: Icon(Icons.image_search_outlined),
            selectedIcon: Icon(Icons.image_search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: orderProvider.pendingCount > 0,
              label: Text('${orderProvider.pendingCount}'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: orderProvider.pendingCount > 0,
              label: Text('${orderProvider.pendingCount}'),
              child: const Icon(Icons.receipt_long),
            ),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
