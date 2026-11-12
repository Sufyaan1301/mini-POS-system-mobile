import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/addon_model.dart';

class AddonFormResult {
  const AddonFormResult({
    required this.name,
    required this.price,
    required this.stock,
  });

  final String name;
  final double price;
  final int stock;
}

/// Dialog for creating or updating an add-on / topping.
Future<AddonFormResult?> showAddonFormDialog(
  BuildContext context, {
  AddonModel? existing,
}) {
  return showDialog<AddonFormResult>(
    context: context,
    builder: (_) => _AddonFormDialog(existing: existing),
  );
}

class _AddonFormDialog extends StatefulWidget {
  const _AddonFormDialog({this.existing});

  final AddonModel? existing;

  @override
  State<_AddonFormDialog> createState() => _AddonFormDialogState();
}

class _AddonFormDialogState extends State<_AddonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      AddonFormResult(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Add-on' : 'Tambah Add-on'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Nama Add-on / Topping',
                hint: 'Contoh: Extra Shot, Keju, Boba',
                prefixIcon: Icons.add_circle_outline,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama add-on wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _priceController,
                label: 'Harga Tambahan (Rp)',
                hint: 'Contoh: 5000',
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Harga wajib diisi';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Harga tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _stockController,
                label: 'Jumlah Stok',
                hint: 'Contoh: 20',
                prefixIcon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            ],
          ),
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
