import 'package:equatable/equatable.dart';

import '../../../pos/data/models/transaction_receipt_model.dart';

/// Daily revenue and transaction count point used for the Sales Dashboard chart.
class DailySalesPoint extends Equatable {
  const DailySalesPoint({
    required this.date,
    required this.revenue,
    required this.transactionCount,
  });

  final DateTime date;
  final double revenue;
  final int transactionCount;

  @override
  List<Object?> get props => [date, revenue, transactionCount];
}

/// Top-selling product aggregated from immutable transaction item snapshots.
class TopSellingProduct extends Equatable {
  const TopSellingProduct({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  final String productName;
  final int quantitySold;
  final double revenue;

  @override
  List<Object?> get props => [productName, quantitySold, revenue];
}

/// Aggregated offline sales report for a selected date range.
class SalesReportModel extends Equatable {
  const SalesReportModel({
    required this.totalRevenue,
    required this.transactionCount,
    required this.totalItemsSold,
    required this.averageOrderValue,
    required this.dailySeries,
    required this.topProducts,
    required this.transactions,
  });

  final double totalRevenue;
  final int transactionCount;
  final int totalItemsSold;
  final double averageOrderValue;
  final List<DailySalesPoint> dailySeries;
  final List<TopSellingProduct> topProducts;
  final List<TransactionReceiptModel> transactions;

  @override
  List<Object?> get props => [
        totalRevenue,
        transactionCount,
        totalItemsSold,
        averageOrderValue,
        dailySeries,
        topProducts,
        transactions,
      ];
}
