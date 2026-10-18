import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/finance_summary.dart';
import '../../../domain/usecases/export_finance_report.dart';
import '../../../domain/usecases/get_daily_totals.dart';
import '../../../domain/usecases/get_finance_summary.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final GetFinanceSummary getFinanceSummary;
  final GetDailyTotals getDailyTotals;
  final ExportFinanceReport exportFinanceReport;

  ReportsCubit({
    required this.getFinanceSummary,
    required this.getDailyTotals,
    required this.exportFinanceReport,
  }) : super(ReportsState(
          selectedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
          summary: FinanceSummary.zero(
            month: DateTime(DateTime.now().year, DateTime.now().month, 1),
          ),
        ));

  Future<void> load({DateTime? month, String? rangeMode}) async {
    final targetMonth = month ?? state.selectedMonth;
    final targetMode = rangeMode ?? state.rangeMode;

    emit(state.copyWith(
      isLoading: true,
      selectedMonth: targetMonth,
      rangeMode: targetMode,
      clearError: true,
      clearExportedPath: true,
    ));

    final summaryResult = await getFinanceSummary(targetMonth);

    DateTime from;
    DateTime to;

    if (targetMode == 'day') {
      final now = DateTime.now();
      from = DateTime(now.year, now.month, now.day);
      to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    } else if (targetMode == 'week') {
      final now = DateTime.now();
      from = now.subtract(const Duration(days: 6));
      to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    } else {
      from = DateTime(targetMonth.year, targetMonth.month, 1);
      to = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59, 999);
    }

    final totalsResult = await getDailyTotals(from: from, to: to);

    summaryResult.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (summary) {
        totalsResult.fold(
          (failure) => emit(state.copyWith(
            isLoading: false,
            summary: summary,
            errorMessage: failure.message,
          )),
          (totals) => emit(state.copyWith(
            isLoading: false,
            summary: summary,
            dailyTotals: totals,
          )),
        );
      },
    );
  }

  void setRangeMode(String mode) {
    load(rangeMode: mode);
  }

  void setMonth(DateTime month) {
    load(month: month);
  }

  Future<String?> exportPdf() async {
    emit(state.copyWith(isExporting: true, clearError: true));
    final result = await exportFinanceReport.pdf(state.selectedMonth);
    return result.fold(
      (failure) {
        emit(state.copyWith(isExporting: false, errorMessage: failure.message));
        return null;
      },
      (path) {
        emit(state.copyWith(isExporting: false, exportedFilePath: path));
        return path;
      },
    );
  }

  Future<String?> exportCsv() async {
    emit(state.copyWith(isExporting: true, clearError: true));
    final result = await exportFinanceReport.csv(state.selectedMonth);
    return result.fold(
      (failure) {
        emit(state.copyWith(isExporting: false, errorMessage: failure.message));
        return null;
      },
      (path) {
        emit(state.copyWith(isExporting: false, exportedFilePath: path));
        return path;
      },
    );
  }
}
