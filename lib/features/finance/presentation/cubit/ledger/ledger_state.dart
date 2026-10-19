import 'package:equatable/equatable.dart';
import '../../../domain/entities/daily_total.dart';
import '../../../domain/entities/finance_enums.dart';
import '../../../domain/entities/ledger_entry.dart';

sealed class LedgerState extends Equatable {
  const LedgerState();

  @override
  List<Object?> get props => [];
}

final class LedgerInitial extends LedgerState {
  const LedgerInitial();
}

final class LedgerLoading extends LedgerState {
  final LedgerType filter;
  final DateTime selectedMonth;

  const LedgerLoading({
    required this.filter,
    required this.selectedMonth,
  });

  @override
  List<Object?> get props => [filter, selectedMonth];
}

final class LedgerLoaded extends LedgerState {
  final List<LedgerEntry> entries;
  final Map<DateTime, List<LedgerEntry>> groupedByDay;
  final Map<DateTime, DailyTotal> dailyTotals;
  final LedgerType filter;
  final DateTime selectedMonth;
  final bool hasMore;
  final bool isLoadingMore;
  final int totalCount;

  const LedgerLoaded({
    required this.entries,
    required this.groupedByDay,
    required this.dailyTotals,
    required this.filter,
    required this.selectedMonth,
    this.hasMore = false,
    this.isLoadingMore = false,
    int? totalCount,
  }) : totalCount = totalCount ?? entries.length;

  LedgerLoaded copyWith({
    List<LedgerEntry>? entries,
    Map<DateTime, List<LedgerEntry>>? groupedByDay,
    Map<DateTime, DailyTotal>? dailyTotals,
    LedgerType? filter,
    DateTime? selectedMonth,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalCount,
  }) {
    return LedgerLoaded(
      entries: entries ?? this.entries,
      groupedByDay: groupedByDay ?? this.groupedByDay,
      dailyTotals: dailyTotals ?? this.dailyTotals,
      filter: filter ?? this.filter,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [
        entries,
        groupedByDay,
        dailyTotals,
        filter,
        selectedMonth,
        hasMore,
        isLoadingMore,
        totalCount,
      ];
}

final class LedgerEmpty extends LedgerState {
  final LedgerType filter;
  final DateTime selectedMonth;

  const LedgerEmpty({
    required this.filter,
    required this.selectedMonth,
  });

  @override
  List<Object?> get props => [filter, selectedMonth];
}

final class LedgerError extends LedgerState {
  final String message;
  final LedgerType filter;
  final DateTime selectedMonth;

  const LedgerError({
    required this.message,
    required this.filter,
    required this.selectedMonth,
  });

  @override
  List<Object?> get props => [message, filter, selectedMonth];
}
