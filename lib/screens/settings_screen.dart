import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/providers/settings_provider.dart';
import 'package:boutique_manager/services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Role
          Text('Your Role', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    settings.isOwner ? Icons.storefront : Icons.shopping_bag,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(settings.isOwner ? 'Shop Owner' : 'Client / Buyer'),
                  subtitle: Text(settings.isOwner
                      ? 'Managing your shop inventory & orders'
                      : 'Browsing products & placing orders'),
                  trailing: TextButton(
                    onPressed: () => _switchRole(context, settings),
                    child: const Text('Switch'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Shop name
          Text('Shop', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Shop Name'),
              subtitle: Text(settings.shopName),
              trailing: const Icon(Icons.edit),
              onTap: () => _editShopName(context, settings),
            ),
          ),
          const SizedBox(height: 24),

          // Appearance
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (v) {
                if (v != null) settings.setThemeMode(v);
              },
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cloud sync
          Text('Cloud Sync (Supabase)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    settings.isCloudConfigured
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    color: settings.isCloudConfigured
                        ? Colors.green
                        : theme.colorScheme.outline,
                  ),
                  title: Text(settings.isCloudConfigured
                      ? 'Cloud Connected'
                      : 'Not Configured'),
                  subtitle: Text(settings.isCloudConfigured
                      ? 'Data syncs over Wi-Fi automatically'
                      : 'App works offline. Configure to enable backup.'),
                  trailing: TextButton(
                    onPressed: () =>
                        _showSupabaseConfig(context, settings),
                    child: Text(
                        settings.isCloudConfigured ? 'Edit' : 'Setup'),
                  ),
                ),
                if (settings.isCloudConfigured)
                  ListTile(
                    leading: _isSyncing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    title: const Text('Sync Now'),
                    onTap: _isSyncing ? null : _syncNow,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          Text('About', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Boutique Manager'),
                  subtitle: Text('v2.0.0 • Marketplace Edition'),
                ),
                ListTile(
                  leading: const Icon(Icons.volunteer_activism),
                  title: const Text('Built with FOSS'),
                  subtitle: const Text(
                      'Flutter • SQLite • Supabase Free Tier'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _switchRole(BuildContext context, SettingsProvider settings) {
    final newRole = settings.isOwner ? UserRole.client : UserRole.owner;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch Role'),
        content: Text(
          'Switch to ${newRole == UserRole.owner ? "Shop Owner" : "Client"}? '
          'The app will show a different interface.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await settings.setUserRole(newRole);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  void _editShopName(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.shopName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shop Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Enter shop name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              settings.setShopName(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSupabaseConfig(
      BuildContext context, SettingsProvider settings) {
    final urlCtrl = TextEditingController(text: settings.supabaseUrl);
    final keyCtrl = TextEditingController(text: settings.supabaseAnonKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supabase Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your free Supabase project credentials. '
              'The app works fully offline without this.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration:
                  const InputDecoration(labelText: 'Project URL'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: keyCtrl,
              decoration:
                  const InputDecoration(labelText: 'Anon Key'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final url = urlCtrl.text.trim();
              final key = keyCtrl.text.trim();
              if (url.isNotEmpty && key.isNotEmpty) {
                settings.setSupabaseConfig(url, key);
                await SyncService.instance
                    .init(supabaseUrl: url, supabaseAnonKey: key);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await SyncService.instance.syncToCloud();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
    setState(() => _isSyncing = false);
  }
}
