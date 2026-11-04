import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/members_table.dart';
import 'tables/packages_table.dart';
import 'tables/subscriptions_table.dart';
import 'tables/subscription_periods_table.dart';
import 'tables/installments_table.dart';
import 'tables/payments_table.dart';
import 'tables/expenses_table.dart';
import 'tables/member_notes_table.dart';
import 'tables/attendance_logs_table.dart';
import 'daos/dashboard_dao.dart';
import 'daos/members_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/memberships_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/finance_dao.dart';
import 'daos/attendance_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Members,
    Packages,
    Subscriptions,
    SubscriptionPeriods,
    Installments,
    Payments,
    Expenses,
    MemberNotes,
    AttendanceLogs,
  ],
  daos: [
    DashboardDao,
    MembersDao,
    NotesDao,
    MembershipsDao,
    PaymentsDao,
    ExpensesDao,
    FinanceDao,
    AttendanceDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(e ?? driftDatabase(name: 'gym_management_app'));

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(members, members.age);
            await m.addColumn(members, members.weightKg);
            await m.addColumn(members, members.heightCm);
            await m.addColumn(members, members.isSuspended);
            await m.addColumn(members, members.searchName);
            await m.addColumn(members, members.updatedAt);
            await m.createTable(memberNotes);
          }
          if (from < 3) {
            await m.addColumn(packages, packages.durationValue);
            await m.addColumn(packages, packages.durationUnit);
            await m.addColumn(packages, packages.isActive);
            await m.addColumn(subscriptions, subscriptions.packageNameSnapshot);
            await m.addColumn(subscriptions, subscriptions.priceSnapshot);
            await m.addColumn(subscriptions, subscriptions.pausedAt);
            await m.addColumn(subscriptions, subscriptions.pauseReason);
            await m.addColumn(subscriptions, subscriptions.totalPausedDays);
            await m.addColumn(subscriptions, subscriptions.amountPaid);
          }
          if (from < 4) {
            await m.createTable(subscriptionPeriods);
            await m.createTable(installments);
            await m.addColumn(payments, payments.periodId);
            await m.addColumn(payments, payments.installmentId);

            final existingSubs = await select(subscriptions).get();
            for (final sub in existingSubs) {
              final subPayments = await (select(payments)
                    ..where((p) => p.subscriptionId.equals(sub.id)))
                  .get();

              final totalPaid =
                  subPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
              final due = sub.priceSnapshot ?? totalPaid;
              final isPaid = totalPaid >= due && due > 0;
              final status =
                  isPaid ? 'paid' : (totalPaid > 0 ? 'partial' : 'unpaid');

              final periodId = await into(subscriptionPeriods).insert(
                SubscriptionPeriodsCompanion.insert(
                  subscriptionId: sub.id,
                  periodNumber: const Value(1),
                  startDate: sub.startDate,
                  endDate: sub.endDate,
                  amountDue: due,
                  paymentStatus: Value(status),
                  isFullyPaid: Value(isPaid),
                  fullyPaidAt: Value(
                    isPaid && subPayments.isNotEmpty
                        ? subPayments.last.paidAt
                        : null,
                  ),
                ),
              );

              final instId = await into(installments).insert(
                InstallmentsCompanion.insert(
                  periodId: periodId,
                  installmentNumber: const Value(1),
                  amount: due,
                  paidAmount: Value(totalPaid),
                  dueDate: sub.startDate,
                  status: Value(isPaid ? 'paid' : 'pending'),
                  paidAt: Value(
                    isPaid && subPayments.isNotEmpty
                        ? subPayments.last.paidAt
                        : null,
                  ),
                  paymentMethod: Value(
                    subPayments.isNotEmpty
                        ? subPayments.first.paymentMethod
                        : 'cash',
                  ),
                ),
              );

              await (update(payments)
                    ..where((p) => p.subscriptionId.equals(sub.id)))
                  .write(
                PaymentsCompanion(
                  periodId: Value(periodId),
                  installmentId: Value(instId),
                ),
              );
            }
          }
          Future<void> safeAddColumn(String table, String column, String definition) async {
            try {
              final rows = await customSelect('PRAGMA table_info($table);').get();
              final columnExists = rows.any((r) => r.read<String>('name') == column);
              if (!columnExists) {
                await customStatement('ALTER TABLE $table ADD COLUMN $column $definition;');
              }
            } catch (_) {}
          }

          if (from < 5) {
            await customStatement('DROP TABLE IF EXISTS attendance;');
          }
          if (from < 6) {
            await safeAddColumn('members', 'gender', 'TEXT');
          }
          if (from < 7) {
            await safeAddColumn('payments', 'member_name_snapshot', 'TEXT');
            await safeAddColumn('payments', 'created_at', 'INTEGER NOT NULL DEFAULT 0');
            await safeAddColumn('payments', 'voided_at', 'INTEGER');
            await safeAddColumn('payments', 'void_reason', 'TEXT');
            await safeAddColumn('expenses', 'custom_label', 'TEXT');
            await safeAddColumn('expenses', 'payment_method', 'TEXT');
            await safeAddColumn('expenses', 'created_at', 'INTEGER NOT NULL DEFAULT 0');
            await safeAddColumn('expenses', 'voided_at', 'INTEGER');
          }
          if (from < 8) {
            await safeAddColumn('packages', 'track_attendance', 'INTEGER NOT NULL DEFAULT 0');
            await safeAddColumn('subscriptions', 'track_attendance', 'INTEGER NOT NULL DEFAULT 0');
            await m.createTable(attendanceLogs);
            await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_logs_sub_attended ON attendance_logs (subscription_id, attended_on);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_attendance_logs_member_id ON attendance_logs (member_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_attendance_logs_subscription_id ON attendance_logs (subscription_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_attendance_logs_attended_on ON attendance_logs (attended_on);');
          }
          if (from < 9) {
            await safeAddColumn('packages', 'is_pay_as_you_go', 'INTEGER NOT NULL DEFAULT 0');
            await safeAddColumn('subscriptions', 'is_pay_as_you_go', 'INTEGER NOT NULL DEFAULT 0');
          }
        },
        beforeOpen: (details) async {
          await customStatement('DROP TABLE IF EXISTS attendance;');
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA synchronous = NORMAL;');
          await customStatement('PRAGMA temp_store = MEMORY;');
          await customStatement('PRAGMA cache_size = -2000;');
          try {
            await customStatement('''
              UPDATE subscriptions
              SET price_snapshot = (SELECT price FROM packages WHERE packages.id = subscriptions.package_id)
              WHERE price_snapshot IS NULL AND package_id IS NOT NULL;
            ''');
            await customStatement('''
              UPDATE subscriptions
              SET package_name_snapshot = (SELECT name FROM packages WHERE packages.id = subscriptions.package_id)
              WHERE package_name_snapshot IS NULL AND package_id IS NOT NULL;
            ''');
          } catch (_) {}
        },
      );

  /// Automatically purges payments older than 3 months ago (before the beginning of the month 3 months prior to current month).
  Future<int> cleanupPaymentsOlderThanThreeMonths({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final cutoff = DateTime(now.year, now.month - 3, 1);
    return (delete(payments)..where((p) => p.paidAt.isSmallerThanValue(cutoff))).go();
  }

  /// Deletes all data from all tables, leaving the database completely clean.
  Future<void> clearAllData() async {
    await customStatement('DROP TABLE IF EXISTS attendance;');
    await customStatement('PRAGMA foreign_keys = OFF;');
    await delete(attendanceLogs).go();
    await delete(memberNotes).go();
    await delete(payments).go();
    await delete(installments).go();
    await delete(subscriptionPeriods).go();
    await delete(subscriptions).go();
    await delete(expenses).go();
    await delete(members).go();
    await delete(packages).go();
    await customStatement('PRAGMA foreign_keys = ON;');
  }
}
