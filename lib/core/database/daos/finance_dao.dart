import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/payments_table.dart';
import '../tables/expenses_table.dart';
import '../tables/members_table.dart';
import '../tables/subscriptions_table.dart';
import '../tables/packages_table.dart';
import '../tables/subscription_periods_table.dart';

part 'finance_dao.g.dart';

class RawLedgerRow {
  final String id;
  final int originalId;
  final String type; // 'income' | 'expense'
  final double amount;
  final DateTime date;
  final String title;
  final String? subtitle;
  final String? method;
  final int? memberId;
  final String? memberPhone;
  final String? memberAvatarUrl;
  final String? category;
  final bool isVoided;
  final String? voidReason;

  const RawLedgerRow({
    required this.id,
    required this.originalId,
    required this.type,
    required this.amount,
    required this.date,
    required this.title,
    this.subtitle,
    this.method,
    this.memberId,
    this.memberPhone,
    this.memberAvatarUrl,
    this.category,
    required this.isVoided,
    this.voidReason,
  });
}

class MemberWithBalanceRow {
  final int memberId;
  final String memberName;
  final String memberPhone;
  final String? memberAvatarUrl;
  final double totalDue;
  final double totalPaid;
  final double remaining;
  final DateTime? lastPaymentDate;
  final int? activeSubscriptionId;
  final String? activePackageName;

  const MemberWithBalanceRow({
    required this.memberId,
    required this.memberName,
    required this.memberPhone,
    this.memberAvatarUrl,
    required this.totalDue,
    required this.totalPaid,
    required this.remaining,
    this.lastPaymentDate,
    this.activeSubscriptionId,
    this.activePackageName,
  });
}

class DailyTotalRow {
  final DateTime date;
  final double revenue;
  final double expenses;
  final double net;

  const DailyTotalRow({
    required this.date,
    required this.revenue,
    required this.expenses,
    required this.net,
  });
}

class MonthlySummaryRow {
  final DateTime month;
  final double revenue;
  final double expenses;
  final double net;

  const MonthlySummaryRow({
    required this.month,
    required this.revenue,
    required this.expenses,
    required this.net,
  });
}

@DriftAccessor(tables: [
  Payments,
  Expenses,
  Members,
  Subscriptions,
  Packages,
  SubscriptionPeriods,
])
class FinanceDao extends DatabaseAccessor<AppDatabase> with _$FinanceDaoMixin {
  FinanceDao(super.db);

  Stream<List<RawLedgerRow>> watchLedger({
    DateTime? from,
    DateTime? to,
    String? typeFilter, // 'all', 'income', 'expense'
  }) {
    return customSelect(
      'SELECT 1',
      readsFrom: {payments, expenses, members, subscriptions, packages},
    ).watch().asyncMap((_) async {
      return getLedgerEntries(from: from, to: to, typeFilter: typeFilter);
    });
  }

  Future<List<RawLedgerRow>> getLedgerEntries({
    DateTime? from,
    DateTime? to,
    String? typeFilter,
  }) async {
    final List<RawLedgerRow> entries = [];

    final bool includeIncome = typeFilter == null || typeFilter == 'all' || typeFilter == 'income';
    final bool includeExpense = typeFilter == null || typeFilter == 'all' || typeFilter == 'expense';

    if (includeIncome) {
      final paymentsQuery = select(payments).join([
        leftOuterJoin(members, members.id.equalsExp(payments.memberId)),
        leftOuterJoin(subscriptions, subscriptions.id.equalsExp(payments.subscriptionId)),
        leftOuterJoin(packages, packages.id.equalsExp(subscriptions.packageId)),
      ]);

      if (from != null) {
        paymentsQuery.where(payments.paidAt.isBiggerOrEqualValue(from));
      }
      if (to != null) {
        paymentsQuery.where(payments.paidAt.isSmallerOrEqualValue(to));
      }

      paymentsQuery.orderBy([OrderingTerm.desc(payments.paidAt)]);

      final paymentRows = await paymentsQuery.get();
      for (final row in paymentRows) {
        final payment = row.readTable(payments);
        final member = row.readTableOrNull(members);
        final sub = row.readTableOrNull(subscriptions);
        final pkg = row.readTableOrNull(packages);

        final memberName = member?.name ?? payment.memberNameSnapshot ?? 'مشترك';
        final packageName = sub?.packageNameSnapshot ?? pkg?.name;
        final subtitle = [
          ?packageName,
          if (payment.notes != null && payment.notes!.isNotEmpty) payment.notes!,
        ].join(' · ');

        entries.add(RawLedgerRow(
          id: 'payment_${payment.id}',
          originalId: payment.id,
          type: 'income',
          amount: payment.amount,
          date: payment.paidAt,
          title: memberName,
          subtitle: subtitle.isNotEmpty ? subtitle : null,
          method: payment.paymentMethod,
          memberId: payment.memberId,
          memberPhone: member?.phone,
          memberAvatarUrl: member?.photoPath,
          category: null,
          isVoided: payment.voidedAt != null,
          voidReason: payment.voidReason,
        ));
      }
    }

    if (includeExpense) {
      final expensesQuery = select(expenses);
      if (from != null) {
        expensesQuery.where((e) => e.date.isBiggerOrEqualValue(from));
      }
      if (to != null) {
        expensesQuery.where((e) => e.date.isSmallerOrEqualValue(to));
      }
      expensesQuery.orderBy([(e) => OrderingTerm.desc(e.date)]);

      final expenseRows = await expensesQuery.get();
      for (final expense in expenseRows) {
        final title = expense.category == 'other' && expense.customLabel != null && expense.customLabel!.isNotEmpty
            ? expense.customLabel!
            : (expense.title.isNotEmpty ? expense.title : expense.category);

        entries.add(RawLedgerRow(
          id: 'expense_${expense.id}',
          originalId: expense.id,
          type: 'expense',
          amount: expense.amount,
          date: expense.date,
          title: title,
          subtitle: expense.notes,
          method: expense.paymentMethod,
          memberId: null,
          memberPhone: null,
          memberAvatarUrl: null,
          category: expense.category,
          isVoided: expense.voidedAt != null,
          voidReason: null,
        ));
      }
    }

    // Sort combined entries descending by date
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<MonthlySummaryRow> getMonthlySummary(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);

    final revSum = payments.amount.sum();
    final revQuery = selectOnly(payments)
      ..addColumns([revSum])
      ..where(
        payments.paidAt.isBiggerOrEqualValue(start) &
        payments.paidAt.isSmallerOrEqualValue(end) &
        payments.voidedAt.isNull(),
      );
    final revResult = await revQuery.map((row) => row.read(revSum)).getSingle();
    final revenue = revResult ?? 0.0;

    final expSum = expenses.amount.sum();
    final expQuery = selectOnly(expenses)
      ..addColumns([expSum])
      ..where(
        expenses.date.isBiggerOrEqualValue(start) &
        expenses.date.isSmallerOrEqualValue(end) &
        expenses.voidedAt.isNull(),
      );
    final expResult = await expQuery.map((row) => row.read(expSum)).getSingle();
    final expenseTotal = expResult ?? 0.0;

    return MonthlySummaryRow(
      month: month,
      revenue: revenue,
      expenses: expenseTotal,
      net: revenue - expenseTotal,
    );
  }

  Stream<MonthlySummaryRow> watchMonthlySummary(DateTime month) {
    return customSelect(
      'SELECT 1',
      readsFrom: {payments, expenses},
    ).watch().asyncMap((_) => getMonthlySummary(month));
  }

  Future<List<DailyTotalRow>> getDailyTotals({
    required DateTime from,
    required DateTime to,
  }) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

    final paymentList = await (select(payments)
          ..where((p) =>
              p.paidAt.isBiggerOrEqualValue(start) &
              p.paidAt.isSmallerOrEqualValue(end) &
              p.voidedAt.isNull()))
        .get();

    final expenseList = await (select(expenses)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(start) &
              e.date.isSmallerOrEqualValue(end) &
              e.voidedAt.isNull()))
        .get();

    final Map<DateTime, double> dailyRevenue = {};
    final Map<DateTime, double> dailyExpenses = {};

    for (final p in paymentList) {
      final dayKey = DateTime(p.paidAt.year, p.paidAt.month, p.paidAt.day);
      dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0.0) + p.amount;
    }

    for (final e in expenseList) {
      final dayKey = DateTime(e.date.year, e.date.month, e.date.day);
      dailyExpenses[dayKey] = (dailyExpenses[dayKey] ?? 0.0) + e.amount;
    }

    final allDays = <DateTime>{...dailyRevenue.keys, ...dailyExpenses.keys}.toList();
    allDays.sort((a, b) => a.compareTo(b));

    return allDays.map((day) {
      final rev = dailyRevenue[day] ?? 0.0;
      final exp = dailyExpenses[day] ?? 0.0;
      return DailyTotalRow(
        date: day,
        revenue: rev,
        expenses: exp,
        net: rev - exp,
      );
    }).toList();
  }

  Future<List<MemberWithBalanceRow>> getMembersWithBalance() async {
    final allMembers = await select(members).get();
    final List<MemberWithBalanceRow> withBalance = [];

    for (final member in allMembers) {
      // 1. Calculate total due from all subscriptions
      final memberSubs = await (select(subscriptions)
            ..where((s) => s.memberId.equals(member.id)))
          .get();

      if (memberSubs.isEmpty) continue;

      double totalDue = 0.0;
      for (final sub in memberSubs) {
        final periods = await (select(subscriptionPeriods)
              ..where((p) => p.subscriptionId.equals(sub.id)))
            .get();

        if (periods.isNotEmpty) {
          for (final period in periods) {
            totalDue += (period.amountDue - period.discount);
          }
        } else {
          totalDue += (sub.priceSnapshot ?? 0.0);
        }
      }

      // 2. Calculate total paid from all non-voided payments
      final memberPayments = await (select(payments)
            ..where((p) => p.memberId.equals(member.id) & p.voidedAt.isNull())
            ..orderBy([(p) => OrderingTerm.desc(p.paidAt)]))
          .get();

      double totalPaid = 0.0;
      for (final p in memberPayments) {
        totalPaid += p.amount;
      }

      final remaining = totalDue - totalPaid;
      if (remaining > 0.01) {
        // Find latest active subscription or latest subscription
        final activeSub = memberSubs.where((s) => s.status == 'active').firstOrNull ?? memberSubs.lastOrNull;

        withBalance.add(MemberWithBalanceRow(
          memberId: member.id,
          memberName: member.name,
          memberPhone: member.phone,
          memberAvatarUrl: member.photoPath,
          totalDue: totalDue,
          totalPaid: totalPaid,
          remaining: remaining,
          lastPaymentDate: memberPayments.isNotEmpty ? memberPayments.first.paidAt : null,
          activeSubscriptionId: activeSub?.id,
          activePackageName: activeSub?.packageNameSnapshot,
        ));
      }
    }

    withBalance.sort((a, b) => b.remaining.compareTo(a.remaining));
    return withBalance;
  }
}
