import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/product_model.dart';
import '../bloc/category/category_bloc.dart';
import '../bloc/product/product_bloc.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/product_image_widget.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.existing});

  final ProductModel? existing;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  int? _selectedCategoryId;
  String? _pickedImagePath;
  bool _removeImage = false;
  bool _awaitingSubmit = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _priceController = TextEditingController(
      text: existing != null ? existing.price.toInt().toString() : '',
    );
    _stockController = TextEditingController(
      text: existing != null ? existing.stock.toString() : '',
    );
    _selectedCategoryId = existing?.categoryId;
    _pickedImagePath = existing?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _pickedImagePath = picked.path;
        _removeImage = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil gambar.')),
      );
    }
  }

  Future<void> _quickAddCategory() async {
    final name = await showCategoryFormDialog(context);
    if (name == null || !mounted) return;
    context.read<CategoryBloc>().add(CategoryAdded(name));
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final stock = int.parse(_stockController.text.trim());

    setState(() => _awaitingSubmit = true);

    final existing = widget.existing;
    if (existing == null) {
      context.read<ProductBloc>().add(
            ProductAdded(
              categoryId: categoryId,
              name: name,
              price: price,
              stock: stock,
              pickedImagePath: _pickedImagePath,
            ),
          );
    } else {
      context.read<ProductBloc>().add(
            ProductUpdated(
              existing: existing,
              categoryId: categoryId,
              name: name,
              price: price,
              stock: stock,
              pickedImagePath: _pickedImagePath,
              removeImage: _removeImage,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (!_awaitingSubmit) return;
        if (state.status == ProductStatus.loaded) {
          setState(() => _awaitingSubmit = false);
          if (state.errorMessage == null) {
            Navigator.of(context).pop();
          }
        }
      },
      builder: (context, productState) {
        final isSubmitting = productState.status == ProductStatus.submitting;

        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildImageSection(),
                          const SizedBox(height: 18),
                          _buildCategoryDropdown(),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _nameController,
                            label: 'Nama Produk',
                            hint: 'Contoh: Milk Coffee',
                            prefixIcon: Icons.local_cafe_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama produk wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _priceController,
                            label: 'Harga Jual (Rp)',
                            hint: 'Contoh: 18000',
                            prefixIcon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Harga jual wajib diisi';
                              }
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null || parsed < 0) {
                                return 'Harga tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _stockController,
                            label: 'Stok Awal',
                            hint: 'Contoh: 25',
                            prefixIcon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Stok wajib diisi';
                              }
                              final parsed = int.tryParse(v.trim());
                              if (parsed == null || parsed < 0) {
                                return 'Stok tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          AppButton(
                            label: isEdit ? 'Simpan Perubahan' : 'Simpan Produk',
                            icon: Icons.save_rounded,
                            isLoading: isSubmitting,
                            onPressed: _onSubmit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection() {
    final displayPath = _removeImage ? null : _pickedImagePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Produk',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ProductImageWidget(
              imagePath: displayPath,
              width: 96,
              height: 96,
              borderRadius: 14,
              iconSize: 38,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Kamera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galeri'),
                  ),
                  if (displayPath != null && displayPath.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _pickedImagePath = null;
                        _removeImage = true;
                      }),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus Foto'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        final categories = catState.categories;
        final validValue = categories.any((c) => c.id == _selectedCategoryId)
            ? _selectedCategoryId
            : null;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey(validValue),
                initialValue: validValue,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                validator: (val) =>
                    val == null ? 'Kategori wajib dipilih' : null,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _quickAddCategory,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}
