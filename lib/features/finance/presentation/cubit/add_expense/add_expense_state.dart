import 'package:equatable/equatable.dart';
import '../../../domain/entities/finance_enums.dart';

class AddExpenseState extends Equatable {
  final ExpenseCategory category;
  final String? customLabel;
  final double amount;
  final DateTime date;
  final PaymentMethod? method;
  final String? note;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  const AddExpenseState({
    this.category = ExpenseCategory.rent,
    this.customLabel,
    this.amount = 0.0,
    required this.date,
    this.method = PaymentMethod.cash,
    this.note,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  AddExpenseState copyWith({
    ExpenseCategory? category,
    String? customLabel,
    double? amount,
    DateTime? date,
    PaymentMethod? method,
    bool clearMethod = false,
    String? note,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddExpenseState(
      category: category ?? this.category,
      customLabel: customLabel ?? this.customLabel,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: clearMethod ? null : (method ?? this.method),
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        category,
        customLabel,
        amount,
        date,
        method,
        note,
        isSubmitting,
        isSuccess,
        errorMessage,
      ];
}
