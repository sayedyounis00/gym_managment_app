import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/members_table.dart';
import 'tables/packages_table.dart';
import 'tables/subscriptions_table.dart';
import 'tables/payments_table.dart';
import 'tables/expenses_table.dart';
import 'tables/member_notes_table.dart';
import 'daos/dashboard_dao.dart';
import 'daos/members_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/memberships_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Members,
    Packages,
    Subscriptions,
    Payments,
    Expenses,
    MemberNotes,
  ],
  daos: [
    DashboardDao,
    MembersDao,
    NotesDao,
    MembershipsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(e ?? driftDatabase(name: 'gym_management_app'));

  @override
  int get schemaVersion => 3;

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
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  /// Deletes all data from all tables, leaving the database completely clean.
  Future<void> clearAllData() async {
    await customStatement('PRAGMA foreign_keys = OFF;');
    await delete(memberNotes).go();
    await delete(payments).go();
    await delete(subscriptions).go();
    await delete(expenses).go();
    await delete(members).go();
    await delete(packages).go();
    await customStatement('PRAGMA foreign_keys = ON;');
  }
}
