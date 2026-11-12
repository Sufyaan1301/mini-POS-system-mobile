part of 'report_bloc.dart';

enum ReportStatus { initial, loading, loaded, error }

class ReportState extends Equatable {
  const ReportState({
    this.status = ReportStatus.initial,
    this.preset = ReportDatePreset.last7Days,
    this.customRange,
    this.report,
    this.selectedDetail,
    this.isDetailLoading = false,
    this.errorMessage,
  });

  final ReportStatus status;
  final ReportDatePreset preset;
  final DateTimeRange? customRange;
  final SalesReportModel? report;
  final TransactionReceiptModel? selectedDetail;
  final bool isDetailLoading;
  final String? errorMessage;

  ReportState copyWith({
    ReportStatus? status,
    ReportDatePreset? preset,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
    SalesReportModel? report,
    TransactionReceiptModel? selectedDetail,
    bool clearSelectedDetail = false,
    bool? isDetailLoading,
    String? errorMessage,
  }) {
    return ReportState(
      status: status ?? this.status,
      preset: preset ?? this.preset,
      customRange:
          clearCustomRange ? null : (customRange ?? this.customRange),
      report: report ?? this.report,
      selectedDetail: clearSelectedDetail
          ? null
          : (selectedDetail ?? this.selectedDetail),
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        preset,
        customRange,
        report,
        selectedDetail,
        isDetailLoading,
        errorMessage,
      ];
}
