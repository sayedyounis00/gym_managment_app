import 'package:equatable/equatable.dart';
import '../../../domain/entities/daily_total.dart';
import '../../../domain/entities/finance_summary.dart';

class ReportsState extends Equatable {
  final bool isLoading;
  final DateTime selectedMonth;
  final String rangeMode; // 'day' | 'week' | 'month'
  final List<DailyTotal> dailyTotals;
  final FinanceSummary summary;
  final bool isExporting;
  final String? exportedFilePath;
  final String? errorMessage;

  const ReportsState({
    this.isLoading = false,
    required this.selectedMonth,
    this.rangeMode = 'month',
    this.dailyTotals = const [],
    required this.summary,
    this.isExporting = false,
    this.exportedFilePath,
    this.errorMessage,
  });

  ReportsState copyWith({
    bool? isLoading,
    DateTime? selectedMonth,
    String? rangeMode,
    List<DailyTotal>? dailyTotals,
    FinanceSummary? summary,
    bool? isExporting,
    String? exportedFilePath,
    bool clearExportedPath = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      rangeMode: rangeMode ?? this.rangeMode,
      dailyTotals: dailyTotals ?? this.dailyTotals,
      summary: summary ?? this.summary,
      isExporting: isExporting ?? this.isExporting,
      exportedFilePath: clearExportedPath ? null : (exportedFilePath ?? this.exportedFilePath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        selectedMonth,
        rangeMode,
        dailyTotals,
        summary,
        isExporting,
        exportedFilePath,
        errorMessage,
      ];
}
