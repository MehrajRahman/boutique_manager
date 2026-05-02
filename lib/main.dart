import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/services/database_service.dart';
import 'package:boutique_manager/services/notification_service.dart';
import 'package:boutique_manager/providers/product_provider.dart';
import 'package:boutique_manager/providers/ledger_provider.dart';
import 'package:boutique_manager/providers/settings_provider.dart';
import 'package:boutique_manager/providers/category_provider.dart';
import 'package:boutique_manager/providers/order_provider.dart';
import 'package:boutique_manager/screens/home_screen.dart';
import 'package:boutique_manager/screens/role_selection_screen.dart';
import 'package:boutique_manager/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database;
  await NotificationService.instance.init();

  final settings = SettingsProvider();
  await settings.init();

  runApp(BoutiqueManagerApp(settings: settings));
}

class BoutiqueManagerApp extends StatelessWidget {
  final SettingsProvider settings;
  const BoutiqueManagerApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => ProductProvider()..loadProducts()),
        ChangeNotifierProvider(create: (_) => LedgerProvider()..loadEntries()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadCategories()),
        ChangeNotifierProvider(create: (_) => OrderProvider()..loadOrders()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Boutique Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            home: settings.hasRole
                ? const HomeScreen()
                : const RoleSelectionScreen(),
          );
        },
      ),
    );
  }
}
