import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/daily_total.dart';
import '../../../domain/entities/finance_enums.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../../domain/usecases/void_expense.dart';
import '../../../domain/usecases/void_payment.dart';
import '../../../domain/usecases/watch_ledger.dart';
import 'ledger_state.dart';

class LedgerCubit extends Cubit<LedgerState> {
  final WatchLedger watchLedger;
  final VoidPayment voidPaymentUseCase;
  final VoidExpense voidExpenseUseCase;

  StreamSubscription? _subscription;
  DateTime _selectedMonth;
  LedgerType _currentFilter;

  LedgerCubit({
    required this.watchLedger,
    required this.voidPaymentUseCase,
    required this.voidExpenseUseCase,
  })  : _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1),
        _currentFilter = LedgerType.all,
        super(const LedgerInitial());

  LedgerType get currentFilter => _currentFilter;
  DateTime get selectedMonth => _selectedMonth;

  void init({DateTime? month, LedgerType? filter}) {
    _selectedMonth = month ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    _currentFilter = filter ?? LedgerType.all;
    _listenToLedger();
  }

  void setFilter(LedgerType filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    _listenToLedger();
  }

  void setMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _listenToMonth();
  }

  void _listenToMonth() {
    _listenToLedger();
  }

  void _listenToLedger() {
    emit(LedgerLoading(filter: _currentFilter, selectedMonth: _selectedMonth));
    _subscription?.cancel();

    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59, 999);

    _subscription = watchLedger(
      from: start,
      to: end,
      filter: _currentFilter == LedgerType.all ? null : _currentFilter,
    ).listen(
      (entries) {
        if (entries.isEmpty) {
          emit(LedgerEmpty(filter: _currentFilter, selectedMonth: _selectedMonth));
          return;
        }

        final Map<DateTime, List<LedgerEntry>> grouped = {};
        final Map<DateTime, DailyTotal> dailyTotals = {};

        for (final entry in entries) {
          final dayKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
          grouped.putIfAbsent(dayKey, () => []).add(entry);

          final currentDaily = dailyTotals[dayKey] ??
              DailyTotal(date: dayKey, revenue: 0, expenses: 0, net: 0);

          if (!entry.isVoided) {
            final isInc = entry.type == LedgerType.income;
            final newRev = isInc ? currentDaily.revenue + entry.amount : currentDaily.revenue;
            final newExp = !isInc ? currentDaily.expenses + entry.amount : currentDaily.expenses;
            dailyTotals[dayKey] = DailyTotal(
              date: dayKey,
              revenue: newRev,
              expenses: newExp,
              net: newRev - newExp,
            );
          } else {
            dailyTotals[dayKey] = currentDaily;
          }
        }

        emit(LedgerLoaded(
          entries: entries,
          groupedByDay: grouped,
          dailyTotals: dailyTotals,
          filter: _currentFilter,
          selectedMonth: _selectedMonth,
        ));
      },
      onError: (err) {
        emit(LedgerError(
          message: err.toString(),
          filter: _currentFilter,
          selectedMonth: _selectedMonth,
        ));
      },
    );
  }

  Future<bool> voidPayment(int paymentId, {String? reason}) async {
    final result = await voidPaymentUseCase(paymentId, reason: reason);
    return result.isRight();
  }

  Future<bool> voidExpense(int expenseId) async {
    final result = await voidExpenseUseCase(expenseId);
    return result.isRight();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
