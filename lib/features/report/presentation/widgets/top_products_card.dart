import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/sales_report_model.dart';

class TopProductsCard extends StatelessWidget {
  const TopProductsCard({
    super.key,
    required this.products,
  });

  final List<TopSellingProduct> products;

  @override
  Widget build(BuildContext context) {
    final maxQty = products.isEmpty
        ? 1
        : products.first.quantitySold.clamp(1, 1 << 30);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Produk Terlaris',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Belum ada produk terjual.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...products.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${item.quantitySold} pcs • ${CurrencyFormatter.format(item.revenue)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: item.quantitySold / maxQty,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(6),
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
