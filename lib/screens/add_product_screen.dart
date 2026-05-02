import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:boutique_manager/providers/product_provider.dart';
import 'package:boutique_manager/providers/category_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');
  final _barcodeController = TextEditingController();

  File? _imageFile;
  bool _showCustomFields = false;
  final _customFields = <MapEntry<TextEditingController, TextEditingController>>[];
  bool _isSaving = false;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _barcodeController.dispose();
    for (final pair in _customFields) {
      pair.key.dispose();
      pair.value.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Save to app's local directory
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/product_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = p.extension(picked.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await File(picked.path).copy('${imagesDir.path}/$fileName');

    setState(() => _imageFile = savedFile);
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(MapEntry(TextEditingController(), TextEditingController()));
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields[index].key.dispose();
      _customFields[index].value.dispose();
      _customFields.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final customFieldsMap = <String, String>{};
    for (final pair in _customFields) {
      final key = pair.key.text.trim();
      final value = pair.value.text.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        customFieldsMap[key] = value;
      }
    }

    await context.read<ProductProvider>().addProduct(
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          quantity: int.parse(_quantityController.text.trim()),
          lowStockThreshold: int.parse(_thresholdController.text.trim()),
          imagePath: _imageFile?.path,
          customFields: customFieldsMap,
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          categoryId: _selectedCategoryId,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            GestureDetector(
              onTap: () => _showImagePicker(context),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 8),
                          Text('Add Product Image',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              )),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Price & Quantity row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Low stock threshold
            TextFormField(
              controller: _thresholdController,
              decoration: const InputDecoration(
                labelText: 'Low Stock Alert Threshold',
                prefixIcon: Icon(Icons.warning_amber_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Barcode
            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode (optional)',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),

            // Category selector
            Builder(
              builder: (context) {
                final categories = context.watch<CategoryProvider>().categories;
                return DropdownButtonFormField<String?>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Folder (optional)',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No folder'),
                    ),
                    ...categories.map((cat) => DropdownMenuItem<String?>(
                          value: cat.id,
                          child: Text(cat.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                );
              },
            ),
            const SizedBox(height: 16),

            // Custom fields toggle
            SwitchListTile(
              title: const Text('Custom Fields'),
              subtitle: const Text('Add extra details like size, color, etc.'),
              value: _showCustomFields,
              onChanged: (v) => setState(() => _showCustomFields = v),
              contentPadding: EdgeInsets.zero,
            ),

            if (_showCustomFields) ...[
              ..._customFields.asMap().entries.map((entry) {
                final idx = entry.key;
                final pair = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: pair.key,
                          decoration: const InputDecoration(
                            labelText: 'Field Name',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: pair.value,
                          decoration: const InputDecoration(
                            labelText: 'Value',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeCustomField(idx),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addCustomField,
                icon: const Icon(Icons.add),
                label: const Text('Add Field'),
              ),
            ],

            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Save Product'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
