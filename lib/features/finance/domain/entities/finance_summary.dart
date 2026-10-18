import 'package:equatable/equatable.dart';

class FinanceSummary extends Equatable {
  final double revenue;
  final double expenses;
  final double net;
  final DateTime selectedMonth;

  const FinanceSummary({
    required this.revenue,
    required this.expenses,
    required this.net,
    required this.selectedMonth,
  });

  const FinanceSummary.zero({required DateTime month})
      : revenue = 0.0,
        expenses = 0.0,
        net = 0.0,
        selectedMonth = month;

  @override
  List<Object?> get props => [revenue, expenses, net, selectedMonth];
}
