import '../../../pos/data/models/transaction_receipt_model.dart';
import '../datasources/report_local_datasource.dart';
import '../models/sales_report_model.dart';

abstract class ReportRepository {
  Future<SalesReportModel> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<TransactionReceiptModel> getTransactionDetail(int transactionId);
}

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({required ReportLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  final ReportLocalDataSource _localDataSource;

  @override
  Future<SalesReportModel> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _localDataSource.getSalesReport(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<TransactionReceiptModel> getTransactionDetail(int transactionId) {
    return _localDataSource.getTransactionDetail(transactionId);
  }
}
