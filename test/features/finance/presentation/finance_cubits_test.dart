import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/features/finance/domain/entities/daily_total.dart';
import 'package:gym_managment_app/features/finance/domain/entities/finance_enums.dart';
import 'package:gym_managment_app/features/finance/domain/entities/finance_summary.dart';
import 'package:gym_managment_app/features/finance/domain/entities/ledger_entry.dart';
import 'package:gym_managment_app/features/finance/domain/entities/member_balance.dart';
import 'package:gym_managment_app/features/finance/domain/repositories/finance_repository.dart';
import 'package:gym_managment_app/features/finance/domain/repositories/payment_repository.dart';
import 'package:gym_managment_app/features/finance/domain/repositories/expense_repository.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/get_members_with_balance.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/void_expense.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/void_payment.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/watch_ledger.dart';
import 'package:gym_managment_app/features/finance/presentation/cubit/balances/balances_cubit.dart';
import 'package:gym_managment_app/features/finance/presentation/cubit/balances/balances_state.dart';
import 'package:gym_managment_app/features/finance/presentation/cubit/finance_overview/finance_overview_cubit.dart';
import 'package:gym_managment_app/features/finance/presentation/cubit/finance_overview/finance_overview_state.dart';
import 'package:gym_managment_app/features/finance/presentation/cubit/ledger/ledger_cubit.dart';
import 'package:gym_managment_app/features/finance/presentation/cubit/ledger/ledger_state.dart';

class FakeFinanceRepository implements FinanceRepository {
  FinanceSummary summary = FinanceSummary(
    revenue: 500.0,
    expenses: 200.0,
    net: 300.0,
    selectedMonth: DateTime(2026, 10, 1),
  );
  List<MemberBalance> balances = [];
  List<LedgerEntry> entries = [];

  @override
  Stream<FinanceSummary> watchSummary(DateTime month) {
    return Stream.value(summary);
  }

  @override
  Future<Either<Failure, FinanceSummary>> getSummary(DateTime month) async {
    return Right(summary);
  }

  @override
  Stream<List<LedgerEntry>> watchLedger({DateTime? from, DateTime? to, LedgerType? filter}) {
    var list = entries;
    if (filter == LedgerType.income) {
      list = list.where((e) => e.type == LedgerType.income).toList();
    } else if (filter == LedgerType.expense) {
      list = list.where((e) => e.type == LedgerType.expense).toList();
    }
    return Stream.value(list);
  }

  @override
  Future<Either<Failure, List<MemberBalance>>> getMembersWithBalance() async {
    return Right(balances);
  }

  @override
  Future<Either<Failure, List<DailyTotal>>> getDailyTotals({required DateTime from, required DateTime to}) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, String>> exportReportPdf(DateTime month) async {
    return const Right('/tmp/report.pdf');
  }

  @override
  Future<Either<Failure, String>> exportReportCsv(DateTime month) async {
    return const Right('/tmp/report.csv');
  }
}

class StubPaymentRepo implements PaymentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubExpenseRepo implements ExpenseRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BalancesCubit', () {
    late FakeFinanceRepository repo;
    late GetMembersWithBalance useCase;
    late BalancesCubit cubit;

    setUp(() {
      repo = FakeFinanceRepository();
      useCase = GetMembersWithBalance(repo);
      cubit = BalancesCubit(getMembersWithBalanceUseCase: useCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('emits BalancesEmpty when no members owe money', () async {
      repo.balances = [];
      await cubit.load();
      expect(cubit.state, isA<BalancesEmpty>());
    });

    test('emits BalancesLoaded and filters by Arabic normalized name or phone', () async {
      repo.balances = [
        const MemberBalance(
          memberId: 1,
          memberName: 'أحمد محمود',
          memberPhone: '01011112222',
          totalDue: 300,
          totalPaid: 100,
          remaining: 200,
        ),
        const MemberBalance(
          memberId: 2,
          memberName: 'إبراهيم حسن',
          memberPhone: '01033334444',
          totalDue: 500,
          totalPaid: 0,
          remaining: 500,
        ),
      ];

      await cubit.load();
      expect(cubit.state, isA<BalancesLoaded>());
      final loaded = cubit.state as BalancesLoaded;
      expect(loaded.allBalances.length, 2);

      // Search 'احمد' without hamza should match 'أحمد'
      cubit.search('احمد');
      final filtered1 = cubit.state as BalancesLoaded;
      expect(filtered1.filteredBalances.length, 1);
      expect(filtered1.filteredBalances.first.memberName, 'أحمد محمود');

      // Search by phone digits
      cubit.search('3333');
      final filtered2 = cubit.state as BalancesLoaded;
      expect(filtered2.filteredBalances.length, 1);
      expect(filtered2.filteredBalances.first.memberName, 'إبراهيم حسن');
    });
  });

  group('FinanceOverviewCubit', () {
    late FakeFinanceRepository repo;
    late GetFinanceSummary useCase;
    late FinanceOverviewCubit cubit;

    setUp(() {
      repo = FakeFinanceRepository();
      useCase = GetFinanceSummary(repo);
      cubit = FinanceOverviewCubit(getFinanceSummary: useCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('loads summary and navigates months', () async {
      cubit.init(DateTime(2026, 10, 1));
      await Future.delayed(Duration.zero);

      expect(cubit.state, isA<FinanceOverviewLoaded>());
      final loaded = cubit.state as FinanceOverviewLoaded;
      expect(loaded.summary.revenue, 500.0);
      expect(loaded.summary.expenses, 200.0);
      expect(loaded.summary.net, 300.0);

      // Navigate to next month
      cubit.nextMonth();
      expect(cubit.selectedMonth.month, 11);

      // Navigate back
      cubit.previousMonth();
      expect(cubit.selectedMonth.month, 10);
    });
  });

  group('LedgerCubit', () {
    late FakeFinanceRepository repo;
    late WatchLedger watchLedger;
    late LedgerCubit cubit;

    setUp(() {
      repo = FakeFinanceRepository();
      watchLedger = WatchLedger(repo);
      cubit = LedgerCubit(
        watchLedger: watchLedger,
        voidPaymentUseCase: VoidPayment(StubPaymentRepo()),
        voidExpenseUseCase: VoidExpense(StubExpenseRepo()),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('emits LedgerEmpty when no entries exist', () async {
      repo.entries = [];
      cubit.init();
      await Future.delayed(Duration.zero);
      expect(cubit.state, isA<LedgerEmpty>());
    });

    test('filters income and expense tabs properly', () async {
      repo.entries = [
        LedgerEntry(
          id: 'p1',
          originalId: 1,
          type: LedgerType.income,
          amount: 200,
          date: DateTime.now(),
          title: 'اشتراك شهري',
          isVoided: false,
        ),
        LedgerEntry(
          id: 'e1',
          originalId: 1,
          type: LedgerType.expense,
          amount: 50,
          date: DateTime.now(),
          title: 'كهرباء',
          isVoided: false,
        ),
      ];

      cubit.init();
      await Future.delayed(Duration.zero);
      expect(cubit.state, isA<LedgerLoaded>());
      var loaded = cubit.state as LedgerLoaded;
      expect(loaded.entries.length, 2);

      // Filter income
      cubit.setFilter(LedgerType.income);
      await Future.delayed(Duration.zero);
      loaded = cubit.state as LedgerLoaded;
      expect(loaded.entries.length, 1);
      expect(loaded.entries.first.type, LedgerType.income);

      // Filter expense
      cubit.setFilter(LedgerType.expense);
      await Future.delayed(Duration.zero);
      loaded = cubit.state as LedgerLoaded;
      expect(loaded.entries.length, 1);
      expect(loaded.entries.first.type, LedgerType.expense);
    });
  });
}
