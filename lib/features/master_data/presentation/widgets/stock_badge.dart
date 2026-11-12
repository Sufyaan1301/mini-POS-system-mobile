import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

/// Color-coded stock badge supporting the Low Stock Indicator bonus feature.
class StockBadge extends StatelessWidget {
  const StockBadge({
    super.key,
    required this.stock,
    this.compact = false,
  });

  final int stock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isOut = stock <= 0;
    final bool isLow = !isOut && stock <= AppConstants.lowStockThreshold;

    final Color fgColor = isOut
        ? AppTheme.dangerColor
        : isLow
            ? const Color(0xFFB45309)
            : AppTheme.successColor;

    final Color bgColor = isOut
        ? AppTheme.dangerColor.withValues(alpha: 0.12)
        : isLow
            ? AppTheme.secondaryColor.withValues(alpha: 0.18)
            : AppTheme.successColor.withValues(alpha: 0.12);

    final String label = isOut
        ? 'Habis'
        : isLow
            ? (compact ? 'Sisa $stock' : 'Stok Rendah: $stock')
            : 'Stok: $stock';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }
}
