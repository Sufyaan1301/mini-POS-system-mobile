import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/sales_report_model.dart';

/// Interactive daily revenue bar chart for offline sales analytics.
class RevenueBarChart extends StatefulWidget {
  const RevenueBarChart({
    super.key,
    required this.points,
  });

  final List<DailySalesPoint> points;

  @override
  State<RevenueBarChart> createState() => _RevenueBarChartState();
}

class _RevenueBarChartState extends State<RevenueBarChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant RevenueBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _selectedIndex =
          widget.points.isNotEmpty ? widget.points.length - 1 : null;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.points.isNotEmpty) {
      _selectedIndex = widget.points.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final dayFormat = DateFormat('dd/MM');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grafik Pendapatan Harian',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                if (_selectedIndex != null && _selectedIndex! < points.length)
                  Text(
                    '${dayFormat.format(points[_selectedIndex!].date)}: '
                    '${CurrencyFormatter.format(points[_selectedIndex!].revenue)} '
                    '(${points[_selectedIndex!].transactionCount} trx)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Belum ada data penjualan pada rentang ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              SizedBox(
                height: 165,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(points.length, (index) {
                      final maxRev = points.fold<double>(
                        1,
                        (maxVal, p) => math.max(maxVal, p.revenue),
                      );
                      final point = points[index];
                      final ratio = (point.revenue / maxRev).clamp(0.05, 1.0);
                      final isSelected = index == _selectedIndex;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: SizedBox(
                          width: 52,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _compactAmount(point.revenue),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: 26,
                                height: 105 * ratio,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.primaryColor
                                          .withValues(alpha: 0.35),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dayFormat.format(point.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _compactAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toStringAsFixed(0);
  }
}
