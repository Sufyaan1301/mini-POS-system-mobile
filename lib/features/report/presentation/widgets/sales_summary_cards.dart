import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../data/models/sales_report_model.dart';

class SalesSummaryCards extends StatelessWidget {
  const SalesSummaryCards({
    super.key,
    required this.report,
  });

  final SalesReportModel report;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);
    final cards = [
      _KpiData(
        label: 'Total Pendapatan',
        value: CurrencyFormatter.format(report.totalRevenue),
        icon: Icons.account_balance_wallet_outlined,
        color: AppTheme.primaryColor,
      ),
      _KpiData(
        label: 'Transaksi Sukses',
        value: '${report.transactionCount}',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF2563EB),
      ),
      _KpiData(
        label: 'Rata-rata Order',
        value: CurrencyFormatter.format(report.averageOrderValue),
        icon: Icons.trending_up_rounded,
        color: AppTheme.secondaryColor,
      ),
      _KpiData(
        label: 'Item Terjual',
        value: '${report.totalItemsSold}',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF7C3AED),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: isTablet ? 1.75 : 1.55,
      ),
      itemBuilder: (context, index) {
        final item = cards[index];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 18, color: item.color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
