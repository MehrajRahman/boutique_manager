import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/models/category.dart' as model;
import 'package:boutique_manager/providers/category_provider.dart';
import 'package:boutique_manager/providers/product_provider.dart';
import 'package:boutique_manager/providers/order_provider.dart';
import 'package:boutique_manager/providers/settings_provider.dart';
import 'package:boutique_manager/screens/category_products_screen.dart';
import 'package:boutique_manager/screens/inventory_screen.dart';
import 'package:boutique_manager/screens/orders_screen.dart';
import 'package:boutique_manager/screens/add_product_screen.dart';

typedef ProductCategory = model.Category;

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ───
          SliverAppBar.large(
            title: Text(settings.shopName),
            actions: [
              if (productProvider.lowStockProducts.isNotEmpty)
                IconButton(
                  icon: Badge(
                    label: Text('${productProvider.lowStockProducts.length}'),
                    child: const Icon(Icons.warning_amber_rounded),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InventoryScreen()),
                  ),
                ),
            ],
          ),

          // ─── Stats Row ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.inventory_2,
                    label: '${productProvider.totalCount}',
                    subtitle: 'Products',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.folder_open,
                    label: '${catProvider.categories.length}',
                    subtitle: 'Folders',
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.pending_actions,
                    label: '${orderProvider.pendingCount}',
                    subtitle: 'Orders',
                    color: theme.colorScheme.tertiary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Section Header: Folders ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Product Folders',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => _showAddCategoryDialog(context),
                    icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
          ),

          // ─── Category Grid ───
          if (catProvider.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator())),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // First item: "All Products"
                    if (index == 0) {
                      return _FolderCard(
                        name: 'All Products',
                        iconData: Icons.grid_view_rounded,
                        productCount: productProvider.totalCount,
                        color: theme.colorScheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryScreen()),
                        ),
                        onLongPress: null,
                      );
                    }

                    // Second: "Uncategorized"
                    if (index == 1) {
                      return _FolderCard(
                        name: 'Uncategorized',
                        iconData: Icons.folder_off_outlined,
                        productCount: catProvider.uncategorizedCount,
                        color: theme.colorScheme.outline,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryProductsScreen(
                              categoryId: null,
                              categoryName: 'Uncategorized',
                            ),
                          ),
                        ),
                        onLongPress: null,
                      );
                    }

                    // Category folders
                    final cat = catProvider.categories[index - 2];
                    final count = catProvider.productCounts[cat.id] ?? 0;
                    return _FolderCard(
                      name: cat.name,
                      iconData: _getCategoryIcon(cat.iconName),
                      productCount: count,
                      color: theme.colorScheme.secondary,
                      coverImagePath: cat.coverImagePath,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryProductsScreen(
                            categoryId: cat.id,
                            categoryName: cat.name,
                          ),
                        ),
                      ),
                      onLongPress: () =>
                          _showCategoryOptionsSheet(context, cat),
                    );
                  },
                  childCount: catProvider.categories.length + 2,
                ),
              ),
            ),

          // ─── Quick Actions ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Quick Actions',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Add Product'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddProductScreen()),
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('View Orders'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.image_search, size: 18),
                    label: const Text('Visual Search'),
                    onPressed: () {
                      // Navigate to visual search from home
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String? selectedIcon;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create Folder',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            // Icon picker
            StatefulBuilder(
              builder: (context, setLocalState) {
                return Wrap(
                  spacing: 8,
                  children: _iconOptions.entries.map((entry) {
                    final isSelected = selectedIcon == entry.key;
                    return ChoiceChip(
                      label: Icon(entry.value, size: 20),
                      selected: isSelected,
                      onSelected: (v) {
                        setLocalState(() =>
                            selectedIcon = v ? entry.key : null);
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                await context.read<CategoryProvider>().addCategory(
                      name: name,
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                      iconName: selectedIcon,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create Folder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryOptionsSheet(BuildContext context, ProductCategory cat) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameCategoryDialog(context, cat);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text('Delete',
                  style: TextStyle(
                      color: Theme.of(ctx).colorScheme.error)),
              subtitle: const Text('Products will be moved to Uncategorized'),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<CategoryProvider>().deleteCategory(cat.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameCategoryDialog(BuildContext context, ProductCategory cat) {
    final controller = TextEditingController(text: cat.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Folder Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await context
                  .read<CategoryProvider>()
                  .updateCategory(cat.copyWith(name: name));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  static IconData _getCategoryIcon(String? iconName) {
    return _iconOptions[iconName] ?? Icons.folder;
  }

  static const _iconOptions = <String, IconData>{
    'clothing': Icons.checkroom,
    'shoes': Icons.ice_skating,
    'jewelry': Icons.diamond,
    'bags': Icons.shopping_bag,
    'beauty': Icons.face,
    'electronics': Icons.devices,
    'home': Icons.home,
    'food': Icons.restaurant,
    'sports': Icons.sports,
    'toys': Icons.toys,
  };
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final IconData iconData;
  final int productCount;
  final Color color;
  final String? coverImagePath;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FolderCard({
    required this.name,
    required this.iconData,
    required this.productCount,
    required this.color,
    this.coverImagePath,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            if (coverImagePath != null && File(coverImagePath!).existsSync())
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(coverImagePath!),
                      fit: BoxFit.cover,
                      color: Colors.black54,
                      colorBlendMode: BlendMode.darken),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: color, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: coverImagePath != null
                              ? Colors.white
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$productCount items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: coverImagePath != null
                              ? Colors.white70
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
