import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/discount_model.dart';
import '../../data/models/transaction_receipt_model.dart';

/// Thermal-style digital receipt preview shared by ReceiptPage and Report detail.
class ReceiptPreviewCard extends StatelessWidget {
  const ReceiptPreviewCard({
    super.key,
    required this.receipt,
  });

  final TransactionReceiptModel receipt;

  @override
  Widget build(BuildContext context) {
    final discountLabel = switch (receipt.discountType) {
      DiscountType.percent =>
        'Diskon (${receipt.discountValue.toStringAsFixed(0)}%)',
      DiscountType.fixed => 'Diskon',
      DiscountType.none => 'Diskon',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppConstants.defaultStoreName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${AppConstants.defaultStoreAddress}\nTelp: ${AppConstants.defaultStorePhone}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Divider(height: 24),
            _metaRow('No. Struk', receipt.invoiceNumber),
            _metaRow('Waktu', DateFormatter.formatReceipt(receipt.createdAt)),
            _metaRow('Kasir', receipt.cashierName),
            const Divider(height: 24),
            ...receipt.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.itemSubtotal),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    ...item.addons.map(
                      (addon) => Padding(
                        padding: const EdgeInsets.only(left: 10, top: 2),
                        child: Text(
                          '+ ${addon.addonName} (${addon.quantity} x ${CurrencyFormatter.format(addon.addonPrice)})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            _summaryRow('Subtotal', CurrencyFormatter.format(receipt.subtotal)),
            if (receipt.discountAmount > 0)
              _summaryRow(
                discountLabel,
                '- ${CurrencyFormatter.format(receipt.discountAmount)}',
                valueColor: Theme.of(context).colorScheme.error,
              ),
            const SizedBox(height: 4),
            _summaryRow(
              'TOTAL',
              CurrencyFormatter.format(receipt.total),
              isBold: true,
              fontSize: 16,
            ),
            const Divider(height: 20),
            _summaryRow(
              'Tunai',
              CurrencyFormatter.format(receipt.cashReceived),
            ),
            _summaryRow(
              'Kembalian',
              CurrencyFormatter.format(receipt.changeAmount),
              isBold: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Terima kasih telah berbelanja!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
