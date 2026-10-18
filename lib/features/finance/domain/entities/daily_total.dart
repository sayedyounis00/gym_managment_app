import 'package:equatable/equatable.dart';

class DailyTotal extends Equatable {
  final DateTime date;
  final double revenue;
  final double expenses;
  final double net;

  const DailyTotal({
    required this.date,
    required this.revenue,
    required this.expenses,
    required this.net,
  });

  @override
  List<Object?> get props => [date, revenue, expenses, net];
}
