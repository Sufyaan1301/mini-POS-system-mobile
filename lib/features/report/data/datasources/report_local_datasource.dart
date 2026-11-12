import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/app_exception.dart';
import '../../../pos/data/models/transaction_receipt_model.dart';
import '../models/sales_report_model.dart';

abstract class ReportLocalDataSource {
  Future<SalesReportModel> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<TransactionReceiptModel> getTransactionDetail(int transactionId);
}

class ReportLocalDataSourceImpl implements ReportLocalDataSource {
  ReportLocalDataSourceImpl({required AppDatabase database})
      : _database = database;

  final AppDatabase _database;

  @override
  Future<SalesReportModel> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _database.database;

      final whereParts = <String>[];
      final whereArgs = <Object?>[];

      if (startDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        whereParts.add('${DbConstants.colCreatedAt} >= ?');
        whereArgs.add(start.toIso8601String());
      }
      if (endDate != null) {
        final end = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
        whereParts.add('${DbConstants.colCreatedAt} <= ?');
        whereArgs.add(end.toIso8601String());
      }

      final whereClause = whereParts.isEmpty ? null : whereParts.join(' AND ');

      final txRows = await db.query(
        DbConstants.tableTransactions,
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: '${DbConstants.colCreatedAt} DESC',
      );

      final transactions =
          txRows.map((row) => TransactionReceiptModel.fromMap(row)).toList();

      final totalRevenue = transactions.fold<double>(
        0,
        (sum, tx) => sum + tx.total,
      );
      final transactionCount = transactions.length;
      final averageOrderValue =
          transactionCount > 0 ? totalRevenue / transactionCount : 0.0;

      final dailyMap = <DateTime, _DailyAccumulator>{};
      for (final tx in transactions) {
        final dayKey = DateTime(
          tx.createdAt.year,
          tx.createdAt.month,
          tx.createdAt.day,
        );
        final acc = dailyMap.putIfAbsent(dayKey, _DailyAccumulator.new);
        acc.revenue += tx.total;
        acc.count += 1;
      }

      final dailySeries = dailyMap.entries
          .map(
            (e) => DailySalesPoint(
              date: e.key,
              revenue: e.value.revenue,
              transactionCount: e.value.count,
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final itemsJoinClause = whereParts.isEmpty
          ? ''
          : 'WHERE ${whereParts.map((w) => 't.$w').join(' AND ')}';

      final totalItemsSold = Sqflite.firstIntValue(
            await db.rawQuery('''
              SELECT COALESCE(SUM(ti.${DbConstants.colQuantity}), 0)
              FROM ${DbConstants.tableTransactionItems} ti
              INNER JOIN ${DbConstants.tableTransactions} t
                ON t.${DbConstants.colId} = ti.${DbConstants.colTransactionId}
              $itemsJoinClause
            ''', whereArgs),
          ) ??
          0;

      final topProductRows = await db.rawQuery('''
        SELECT
          ti.${DbConstants.colProductNameSnapshot} AS product_name,
          SUM(ti.${DbConstants.colQuantity}) AS qty_sold,
          SUM(ti.${DbConstants.colItemSubtotal}) AS revenue
        FROM ${DbConstants.tableTransactionItems} ti
        INNER JOIN ${DbConstants.tableTransactions} t
          ON t.${DbConstants.colId} = ti.${DbConstants.colTransactionId}
        $itemsJoinClause
        GROUP BY ti.${DbConstants.colProductNameSnapshot}
        ORDER BY qty_sold DESC, revenue DESC
        LIMIT 5
      ''', whereArgs);

      final topProducts = topProductRows
          .map(
            (row) => TopSellingProduct(
              productName: row['product_name'] as String,
              quantitySold: (row['qty_sold'] as num).toInt(),
              revenue: (row['revenue'] as num).toDouble(),
            ),
          )
          .toList();

      return SalesReportModel(
        totalRevenue: totalRevenue,
        transactionCount: transactionCount,
        totalItemsSold: totalItemsSold,
        averageOrderValue: averageOrderValue,
        dailySeries: dailySeries,
        topProducts: topProducts,
        transactions: transactions,
      );
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memuat laporan penjualan: $e');
    }
  }

  @override
  Future<TransactionReceiptModel> getTransactionDetail(int transactionId) async {
    try {
      final db = await _database.database;
      final txRows = await db.query(
        DbConstants.tableTransactions,
        where: '${DbConstants.colId} = ?',
        whereArgs: [transactionId],
        limit: 1,
      );
      if (txRows.isEmpty) {
        throw const LocalDatabaseException('Data transaksi tidak ditemukan.');
      }

      final itemRows = await db.query(
        DbConstants.tableTransactionItems,
        where: '${DbConstants.colTransactionId} = ?',
        whereArgs: [transactionId],
        orderBy: '${DbConstants.colId} ASC',
      );

      final items = <TransactionReceiptItem>[];
      for (final itemRow in itemRows) {
        final itemId = itemRow[DbConstants.colId] as int;
        final addonRows = await db.query(
          DbConstants.tableTransactionItemAddons,
          where: '${DbConstants.colTransactionItemId} = ?',
          whereArgs: [itemId],
          orderBy: '${DbConstants.colId} ASC',
        );
        final addons = addonRows.map(TransactionReceiptAddon.fromMap).toList();
        items.add(TransactionReceiptItem.fromMap(itemRow, addons: addons));
      }

      return TransactionReceiptModel.fromMap(txRows.first, items: items);
    } on AppException {
      rethrow;
    } on DatabaseException catch (e) {
      throw LocalDatabaseException('Gagal memuat detail transaksi: $e');
    }
  }
}

class _DailyAccumulator {
  double revenue = 0;
  int count = 0;
}
