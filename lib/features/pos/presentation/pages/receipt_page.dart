import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/transaction_receipt_model.dart';
import '../widgets/receipt_preview_card.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({
    super.key,
    required this.receipt,
  });

  final TransactionReceiptModel receipt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Transaksi'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successColor,
                  size: 56,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pembayaran Berhasil',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                ReceiptPreviewCard(receipt: receipt),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Transaksi Baru',
                  icon: Icons.add_shopping_cart_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
