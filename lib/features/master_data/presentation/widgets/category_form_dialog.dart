import 'package:flutter/material.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/category_model.dart';

/// Dialog for creating or renaming a product category.
Future<String?> showCategoryFormDialog(
  BuildContext context, {
  CategoryModel? existing,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CategoryFormDialog(existing: existing),
  );
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.existing});

  final CategoryModel? existing;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
      content: Form(
        key: _formKey,
        child: AppTextField(
          controller: _nameController,
          label: 'Nama Kategori',
          hint: 'Contoh: Kopi, Makanan, Snack',
          prefixIcon: Icons.category_outlined,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama kategori wajib diisi';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}
