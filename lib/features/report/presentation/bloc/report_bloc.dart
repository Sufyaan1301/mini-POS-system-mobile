import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../pos/data/models/transaction_receipt_model.dart';
import '../../data/models/sales_report_model.dart';
import '../../data/repositories/report_repository.dart';

part 'report_event.dart';
part 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc({required ReportRepository repository})
      : _repository = repository,
        super(const ReportState()) {
    on<ReportLoaded>(_onLoaded);
    on<ReportTransactionDetailRequested>(_onDetailRequested);
  }

  final ReportRepository _repository;

  Future<void> _onLoaded(
    ReportLoaded event,
    Emitter<ReportState> emit,
  ) async {
    final nextPreset = event.preset ?? state.preset;
    final nextCustomRange = event.customRange ?? state.customRange;
    final (startDate, endDate) = _resolveDateBounds(nextPreset, nextCustomRange);

    emit(
      state.copyWith(
        status: ReportStatus.loading,
        preset: nextPreset,
        customRange: nextCustomRange,
        clearCustomRange: nextPreset != ReportDatePreset.custom,
      ),
    );

    try {
      final report = await _repository.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );
      emit(state.copyWith(status: ReportStatus.loaded, report: report));
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: ReportStatus.error,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onDetailRequested(
    ReportTransactionDetailRequested event,
    Emitter<ReportState> emit,
  ) async {
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedDetail: true,
      ),
    );
    try {
      final detail = await _repository.getTransactionDetail(event.transactionId);
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedDetail: detail,
        ),
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          errorMessage: e.message,
        ),
      );
    }
  }

  (DateTime?, DateTime?) _resolveDateBounds(
    ReportDatePreset preset,
    DateTimeRange? customRange,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (preset) {
      ReportDatePreset.today => (today, today),
      ReportDatePreset.last7Days =>
        (today.subtract(const Duration(days: 6)), today),
      ReportDatePreset.last30Days =>
        (today.subtract(const Duration(days: 29)), today),
      ReportDatePreset.all => (null, null),
      ReportDatePreset.custom => (customRange?.start, customRange?.end),
    };
  }
}
