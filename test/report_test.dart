import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos_system/features/pos/data/models/discount_model.dart';
import 'package:mini_pos_system/features/pos/data/models/transaction_receipt_model.dart';
import 'package:mini_pos_system/features/report/data/models/sales_report_model.dart';
import 'package:mini_pos_system/features/report/data/repositories/report_repository.dart';
import 'package:mini_pos_system/features/report/presentation/bloc/report_bloc.dart';

class _FakeReportRepository implements ReportRepository {
  DateTime? lastStart;
  DateTime? lastEnd;

  @override
  Future<SalesReportModel> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    lastStart = startDate;
    lastEnd = endDate;

    return SalesReportModel(
      totalRevenue: 45000,
      transactionCount: 2,
      totalItemsSold: 3,
      averageOrderValue: 22500,
      dailySeries: [
        DailySalesPoint(
          date: DateTime(2026, 11, 12),
          revenue: 45000,
          transactionCount: 2,
        ),
      ],
      topProducts: const [
        TopSellingProduct(
          productName: 'Roti Bakar',
          quantitySold: 2,
          revenue: 30000,
        ),
      ],
      transactions: [
        TransactionReceiptModel(
          id: 1,
          invoiceNumber: 'INV-20261112-001',
          cashierId: 1,
          cashierName: 'Dils',
          subtotal: 30000,
          discountType: DiscountType.none,
          discountValue: 0,
          discountAmount: 0,
          total: 30000,
          cashReceived: 50000,
          changeAmount: 20000,
          createdAt: DateTime(2026, 11, 12, 10, 0),
        ),
      ],
    );
  }

  @override
  Future<TransactionReceiptModel> getTransactionDetail(int transactionId) async {
    return TransactionReceiptModel(
      id: transactionId,
      invoiceNumber: 'INV-20261112-001',
      cashierId: null,
      cashierName: 'Dils',
      subtotal: 15000,
      discountType: DiscountType.none,
      discountValue: 0,
      discountAmount: 0,
      total: 15000,
      cashReceived: 20000,
      changeAmount: 5000,
      createdAt: DateTime(2026, 11, 12, 10, 0),
      items: const [
        TransactionReceiptItem(
          id: 1,
          productId: null, // Deleted master product still renders via snapshot!
          productName: 'Roti Bakar',
          unitPrice: 15000,
          quantity: 1,
          itemSubtotal: 15000,
        ),
      ],
    );
  }
}

void main() {
  group('ReportBloc', () {
    late _FakeReportRepository repo;
    late ReportBloc bloc;

    setUp(() {
      repo = _FakeReportRepository();
      bloc = ReportBloc(repository: repo);
    });

    tearDown(() async => bloc.close());

    test('loads sales summary, chart points, and top products', () async {
      bloc.add(const ReportLoaded(preset: ReportDatePreset.today));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.status, ReportStatus.loaded);
      expect(bloc.state.report?.totalRevenue, 45000);
      expect(bloc.state.report?.transactionCount, 2);
      expect(bloc.state.report?.topProducts.first.productName, 'Roti Bakar');
      expect(repo.lastStart, isNotNull);
      expect(repo.lastEnd, isNotNull);
    });

    test('loads immutable snapshot detail even when productId is null', () async {
      bloc.add(const ReportTransactionDetailRequested(1));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.isDetailLoading, isFalse);
      expect(bloc.state.selectedDetail?.items.first.productName, 'Roti Bakar');
      expect(bloc.state.selectedDetail?.items.first.productId, isNull);
    });
  });
}
