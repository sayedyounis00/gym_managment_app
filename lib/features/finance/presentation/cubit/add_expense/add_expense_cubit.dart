import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/finance_enums.dart';
import '../../../domain/usecases/add_expense.dart';
import '../../../domain/usecases/update_expense.dart';
import 'add_expense_state.dart';

class AddExpenseCubit extends Cubit<AddExpenseState> {
  final AddExpense addExpenseUseCase;
  final UpdateExpense updateExpenseUseCase;

  AddExpenseCubit({
    required this.addExpenseUseCase,
    required this.updateExpenseUseCase,
  }) : super(AddExpenseState(date: DateTime.now()));

  void init({Expense? initialExpense}) {
    if (initialExpense != null) {
      emit(AddExpenseState(
        category: initialExpense.category,
        customLabel: initialExpense.customLabel,
        amount: initialExpense.amount,
        date: initialExpense.date,
        method: initialExpense.method,
        note: initialExpense.note,
      ));
    } else {
      emit(AddExpenseState(date: DateTime.now()));
    }
  }

  void setCategory(ExpenseCategory category) {
    emit(state.copyWith(
      category: category,
      clearError: true,
    ));
  }

  void setCustomLabel(String? label) {
    emit(state.copyWith(
      customLabel: label,
      clearError: true,
    ));
  }

  void setAmount(double amount) {
    emit(state.copyWith(
      amount: amount,
      clearError: true,
    ));
  }

  void setDate(DateTime date) {
    emit(state.copyWith(date: date));
  }

  void setMethod(PaymentMethod? method) {
    emit(state.copyWith(
      method: method,
      clearMethod: method == null,
    ));
  }

  void setNote(String? note) {
    emit(state.copyWith(note: note));
  }

  Future<bool> submit() async {
    if (state.amount <= 0) {
      emit(state.copyWith(errorMessage: 'يرجى إدخال مبلغ صحيح أكبر من صفر'));
      return false;
    }

    if (state.category == ExpenseCategory.other &&
        (state.customLabel == null || state.customLabel!.trim().isEmpty)) {
      emit(state.copyWith(errorMessage: 'يرجى إدخال مسمى المصروف عند اختيار تصنيف "أخرى"'));
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await addExpenseUseCase(
      AddExpenseParams(
        category: state.category,
        customLabel: state.customLabel?.trim(),
        amount: state.amount,
        method: state.method,
        date: state.date,
        note: state.note?.trim(),
      ),
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (id) {
        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
        ));
        return true;
      },
    );
  }

  Future<bool> update(int expenseId) async {
    if (state.amount <= 0) {
      emit(state.copyWith(errorMessage: 'يرجى إدخال مبلغ صحيح أكبر من صفر'));
      return false;
    }

    if (state.category == ExpenseCategory.other &&
        (state.customLabel == null || state.customLabel!.trim().isEmpty)) {
      emit(state.copyWith(errorMessage: 'يرجى إدخال مسمى المصروف عند اختيار تصنيف "أخرى"'));
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await updateExpenseUseCase(
      UpdateExpenseParams(
        expenseId: expenseId,
        category: state.category,
        customLabel: state.customLabel?.trim(),
        amount: state.amount,
        method: state.method,
        date: state.date,
        note: state.note?.trim(),
      ),
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
        ));
        return true;
      },
    );
  }
}
