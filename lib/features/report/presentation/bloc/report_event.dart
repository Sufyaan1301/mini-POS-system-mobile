part of 'report_bloc.dart';

enum ReportDatePreset { today, last7Days, last30Days, all, custom }

sealed class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

final class ReportLoaded extends ReportEvent {
  const ReportLoaded({
    this.preset,
    this.customRange,
  });

  final ReportDatePreset? preset;
  final DateTimeRange? customRange;

  @override
  List<Object?> get props => [preset, customRange];
}

final class ReportTransactionDetailRequested extends ReportEvent {
  const ReportTransactionDetailRequested(this.transactionId);

  final int transactionId;

  @override
  List<Object?> get props => [transactionId];
}
