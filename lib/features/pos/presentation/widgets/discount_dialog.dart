import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/discount_model.dart';

/// Dialog for applying percentage or fixed discounts with boundary validation.
Future<DiscountModel?> showDiscountDialog(
  BuildContext context, {
  required double subtotal,
  required DiscountModel currentDiscount,
}) {
  return showDialog<DiscountModel>(
    context: context,
    builder: (_) => _DiscountDialog(
      subtotal: subtotal,
      currentDiscount: currentDiscount,
    ),
  );
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({
    required this.subtotal,
    required this.currentDiscount,
  });

  final double subtotal;
  final DiscountModel currentDiscount;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late DiscountType _type;

  @override
  void initState() {
    super.initState();
    _type = widget.currentDiscount.type == DiscountType.none
        ? DiscountType.percent
        : widget.currentDiscount.type;
    _valueController = TextEditingController(
      text: widget.currentDiscount.value > 0
          ? widget.currentDiscount.value.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _apply() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final val = double.parse(_valueController.text.trim());
    Navigator.of(context).pop(DiscountModel(type: _type, value: val));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Diskon'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Subtotal: ${CurrencyFormatter.format(widget.subtotal)}',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<DiscountType>(
              segments: const [
                ButtonSegment(
                  value: DiscountType.percent,
                  label: Text('Persen (%)'),
                ),
                ButtonSegment(
                  value: DiscountType.fixed,
                  label: Text('Nominal (Rp)'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _valueController,
              label: _type == DiscountType.percent
                  ? 'Persentase Diskon (%)'
                  : 'Nominal Diskon (Rp)',
              hint: _type == DiscountType.percent ? '0 - 100' : 'Contoh: 5000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nilai diskon wajib diisi';
                }
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed < 0) {
                  return 'Diskon tidak boleh negatif';
                }
                if (_type == DiscountType.percent && parsed > 100) {
                  return 'Diskon persentase maksimal 100%';
                }
                if (_type == DiscountType.fixed && parsed > widget.subtotal) {
                  return 'Diskon tidak boleh melebihi subtotal';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentDiscount.type != DiscountType.none)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const DiscountModel.none()),
            child: const Text('Hapus Diskon'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _apply,
          child: const Text('Terapkan'),
        ),
      ],
    );
  }
}
