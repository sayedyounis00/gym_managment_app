import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_finance_summary.dart';
import 'finance_overview_state.dart';

class FinanceOverviewCubit extends Cubit<FinanceOverviewState> {
  final GetFinanceSummary getFinanceSummary;
  StreamSubscription? _subscription;
  DateTime _selectedMonth;

  FinanceOverviewCubit({required this.getFinanceSummary})
      : _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1),
        super(const FinanceOverviewInitial());

  DateTime get selectedMonth => _selectedMonth;

  void init([DateTime? month]) {
    _selectedMonth = month ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    _listenToMonth();
  }

  void setMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _listenToMonth();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    _listenToMonth();
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    _listenToMonth();
  }

  void _listenToMonth() {
    emit(FinanceOverviewLoading(selectedMonth: _selectedMonth));
    _subscription?.cancel();
    _subscription = getFinanceSummary.watch(_selectedMonth).listen(
      (summary) {
        emit(FinanceOverviewLoaded(
          summary: summary,
          selectedMonth: _selectedMonth,
        ));
      },
      onError: (err) {
        emit(FinanceOverviewError(
          message: err.toString(),
          selectedMonth: _selectedMonth,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
