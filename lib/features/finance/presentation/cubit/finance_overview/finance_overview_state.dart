import 'package:equatable/equatable.dart';
import '../../../domain/entities/finance_summary.dart';

sealed class FinanceOverviewState extends Equatable {
  const FinanceOverviewState();

  @override
  List<Object?> get props => [];
}

final class FinanceOverviewInitial extends FinanceOverviewState {
  const FinanceOverviewInitial();
}

final class FinanceOverviewLoading extends FinanceOverviewState {
  final DateTime selectedMonth;

  const FinanceOverviewLoading({required this.selectedMonth});

  @override
  List<Object?> get props => [selectedMonth];
}

final class FinanceOverviewLoaded extends FinanceOverviewState {
  final FinanceSummary summary;
  final DateTime selectedMonth;

  const FinanceOverviewLoaded({
    required this.summary,
    required this.selectedMonth,
  });

  @override
  List<Object?> get props => [summary, selectedMonth];
}

final class FinanceOverviewError extends FinanceOverviewState {
  final String message;
  final DateTime selectedMonth;

  const FinanceOverviewError({
    required this.message,
    required this.selectedMonth,
  });

  @override
  List<Object?> get props => [message, selectedMonth];
}
