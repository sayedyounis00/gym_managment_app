import 'package:equatable/equatable.dart';
import 'finance_enums.dart';

class Expense extends Equatable {
  final int id;
  final ExpenseCategory category;
  final String? customLabel;
  final double amount;
  final PaymentMethod? method;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime? voidedAt;

  const Expense({
    required this.id,
    required this.category,
    this.customLabel,
    required this.amount,
    this.method,
    required this.date,
    this.note,
    required this.createdAt,
    this.voidedAt,
  });

  bool get isVoided => voidedAt != null;

  String get displayTitle {
    if (category == ExpenseCategory.other &&
        customLabel != null &&
        customLabel!.trim().isNotEmpty) {
      return customLabel!.trim();
    }
    return category.labelArabic;
  }

  @override
  List<Object?> get props => [
        id,
        category,
        customLabel,
        amount,
        method,
        date,
        note,
        createdAt,
        voidedAt,
      ];
}
