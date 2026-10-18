import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/members_table.dart';
import '../tables/packages_table.dart';
import '../tables/subscriptions_table.dart';
import '../tables/payments_table.dart';
import '../tables/expenses_table.dart';

part 'dashboard_dao.g.dart';

class ExpiringSubscriptionRow {
  final int memberId;
  final String memberName;
  final String phone;
  final DateTime endDate;
  final int daysLeft;
  final String? packageName;

  const ExpiringSubscriptionRow({
    required this.memberId,
    required this.memberName,
    required this.phone,
    required this.endDate,
    required this.daysLeft,
    this.packageName,
  });
}

@DriftAccessor(tables: [
  Members,
  Packages,
  Subscriptions,
  Payments,
  Expenses,
])
class DashboardDao extends DatabaseAccessor<AppDatabase> with _$DashboardDaoMixin {
  DashboardDao(super.db);

  Future<int> countActiveMembers() async {
    final count = members.id.count();
    final query = selectOnly(members)
      ..addColumns([count])
      ..where(members.status.equals('active'));
    final result = await query.map((row) => row.read(count)).getSingle();
    return result ?? 0;
  }

  Future<int> countNewSubscriptions({
    required DateTime since,
    required DateTime until,
  }) async {
    final count = subscriptions.id.count();
    final query = selectOnly(subscriptions)
      ..addColumns([count])
      ..join([
        innerJoin(members, members.id.equalsExp(subscriptions.memberId)),
      ])
      ..where(
        subscriptions.startDate.isBiggerOrEqualValue(since) &
        subscriptions.startDate.isSmallerOrEqualValue(until) &
        subscriptions.isRenewal.equals(false) &
        members.status.equals('active'),
      );
    final result = await query.map((row) => row.read(count)).getSingle();
    return result ?? 0;
  }

  Future<List<ExpiringSubscriptionRow>> getExpiringSubscriptions({
    required DateTime now,
    int windowDays = 7,
  }) async {
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endWindow = DateTime(now.year, now.month, now.day + windowDays, 23, 59, 59, 999);

    final query = select(subscriptions).join([
      innerJoin(members, members.id.equalsExp(subscriptions.memberId)),
      leftOuterJoin(packages, packages.id.equalsExp(subscriptions.packageId)),
    ])
      ..where(
        members.status.equals('active') &
        subscriptions.status.equals('active') &
        subscriptions.endDate.isBiggerOrEqualValue(startOfDay) &
        subscriptions.endDate.isSmallerOrEqualValue(endWindow),
      )
      ..orderBy([OrderingTerm.asc(subscriptions.endDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final sub = row.readTable(subscriptions);
      final member = row.readTable(members);
      final package = row.readTableOrNull(packages);
      final diff = sub.endDate.difference(startOfDay).inDays;
      return ExpiringSubscriptionRow(
        memberId: member.id,
        memberName: member.name,
        phone: member.phone,
        endDate: sub.endDate,
        daysLeft: diff < 0 ? 0 : diff,
        packageName: package?.name,
      );
    }).toList();
  }

  Future<double> sumRevenue({
    required DateTime since,
    required DateTime until,
  }) async {
    final sum = payments.amount.sum();
    final query = selectOnly(payments)
      ..addColumns([sum])
      ..where(
        payments.paidAt.isBiggerOrEqualValue(since) &
        payments.paidAt.isSmallerOrEqualValue(until),
      );
    final result = await query.map((row) => row.read(sum)).getSingle();
    return result ?? 0.0;
  }

  Future<double> sumTodayRevenue(DateTime now) async {
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return sumRevenue(since: start, until: end);
  }

  Future<double> sumExpenses({
    required DateTime since,
    required DateTime until,
  }) async {
    final sum = expenses.amount.sum();
    final query = selectOnly(expenses)
      ..addColumns([sum])
      ..where(
        expenses.date.isBiggerOrEqualValue(since) &
        expenses.date.isSmallerOrEqualValue(until),
      );
    final result = await query.map((row) => row.read(sum)).getSingle();
    return result ?? 0.0;
  }

  Stream<void> watchDashboardUpdates() {
    return customSelect(
      'SELECT 1',
      readsFrom: {members, subscriptions, payments, expenses, packages},
    ).watch().map((_) {});
  }
}
