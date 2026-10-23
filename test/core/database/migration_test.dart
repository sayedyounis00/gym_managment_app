import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';

void main() {
  test('AppDatabase schema version is 9 and tables can be queried', () async {
    final db = AppDatabase(NativeDatabase.memory());

    expect(db.schemaVersion, 9);

    // Verify all tables and new columns can be queried
    final packages = await db.select(db.packages).get();
    expect(packages, isEmpty);

    final subscriptions = await db.select(db.subscriptions).get();
    expect(subscriptions, isEmpty);

    final periods = await db.select(db.subscriptionPeriods).get();
    expect(periods, isEmpty);

    final installments = await db.select(db.installments).get();
    expect(installments, isEmpty);

    final members = await db.select(db.members).get();
    expect(members, isEmpty);

    final attendanceLogs = await db.select(db.attendanceLogs).get();
    expect(attendanceLogs, isEmpty);

    await db.close();
  });

  test('migration from v5 to v6 adds gender column with existing members having null gender', () async {
    final tempDir = await Directory.systemTemp.createTemp('gym_migration_test_');
    final dbFile = File('${tempDir.path}/gym_test_v5.db');

    try {
      final v5Executor = NativeDatabase(dbFile);
      await v5Executor.ensureOpen(_DummyUser());

      // Create v5 schema without gender column
      await v5Executor.runCustom('''
        CREATE TABLE members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          photo_path TEXT,
          age INTEGER,
          weight_kg REAL,
          height_cm REAL,
          is_suspended INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'active',
          search_name TEXT,
          created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
          updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
        );
      ''');
      await v5Executor.runCustom('''
        CREATE TABLE packages (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL NOT NULL, duration_in_days INTEGER NOT NULL, duration_value INTEGER NOT NULL DEFAULT 1, duration_unit TEXT NOT NULL DEFAULT 'months', is_active INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL DEFAULT 0);
      ''');
      await v5Executor.runCustom('''
        CREATE TABLE subscriptions (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL REFERENCES members (id), package_id INTEGER REFERENCES packages (id), package_name_snapshot TEXT, price_snapshot REAL, start_date INTEGER NOT NULL, end_date INTEGER NOT NULL, is_renewal INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'active', paused_at INTEGER, pause_reason TEXT, total_paused_days INTEGER NOT NULL DEFAULT 0, amount_paid REAL NOT NULL DEFAULT 0.0, created_at INTEGER NOT NULL DEFAULT 0);
      ''');
      await v5Executor.runCustom('''
        CREATE TABLE subscription_periods (id INTEGER PRIMARY KEY AUTOINCREMENT, subscription_id INTEGER NOT NULL REFERENCES subscriptions (id), period_number INTEGER NOT NULL DEFAULT 1, start_date INTEGER NOT NULL, end_date INTEGER NOT NULL, amount_due REAL NOT NULL, payment_status TEXT NOT NULL DEFAULT 'unpaid', is_fully_paid INTEGER NOT NULL DEFAULT 0, fully_paid_at INTEGER, created_at INTEGER NOT NULL DEFAULT 0);
      ''');
      await v5Executor.runCustom('''
        CREATE TABLE installments (id INTEGER PRIMARY KEY AUTOINCREMENT, period_id INTEGER NOT NULL REFERENCES subscription_periods (id), installment_number INTEGER NOT NULL DEFAULT 1, amount REAL NOT NULL, paid_amount REAL NOT NULL DEFAULT 0.0, due_date INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'pending', paid_at INTEGER, payment_method TEXT NOT NULL DEFAULT 'cash', created_at INTEGER NOT NULL DEFAULT 0);
      ''');
      await v5Executor.runCustom('''
        CREATE TABLE payments (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL REFERENCES members (id), subscription_id INTEGER REFERENCES subscriptions (id), period_id INTEGER REFERENCES subscription_periods (id), installment_id INTEGER REFERENCES installments (id), amount REAL NOT NULL, paid_at INTEGER NOT NULL DEFAULT 0, payment_method TEXT NOT NULL DEFAULT 'cash', notes TEXT);
      ''');
      await v5Executor.runCustom('''
        CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount REAL NOT NULL, category TEXT NOT NULL, date INTEGER NOT NULL, notes TEXT);
      ''');
      await v5Executor.runCustom('''
        CREATE TABLE member_notes (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL REFERENCES members (id) ON DELETE CASCADE, note TEXT NOT NULL, created_at INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0);
      ''');

      // Set schema version to 5 and insert existing member in v5
      await v5Executor.runCustom('PRAGMA user_version = 5;');
      await v5Executor.runCustom("INSERT INTO members (id, name, phone) VALUES (1, 'عضو قديم', '01012345678');");
      await v5Executor.close();

      // Open database with AppDatabase (which will trigger onUpgrade from 5 to 6)
      final v6Executor = NativeDatabase(dbFile);
      final db = AppDatabase(v6Executor);

      final allMembers = await db.select(db.members).get();
      expect(allMembers.length, 1);
      expect(allMembers.first.name, 'عضو قديم');
      expect(allMembers.first.gender, isNull);

      // Insert new member in v6 with gender
      await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'عضو جديد',
          phone: '01099998888',
          gender: const Value('male'),
        ),
      );

      final newMember = await (db.select(db.members)..where((m) => m.id.equals(2))).getSingle();
      expect(newMember.gender, 'male');

      await db.close();
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test('migration from v6 to v7 adds finance columns to payments and expenses', () async {
    final tempDir = await Directory.systemTemp.createTemp('gym_migration_test_v6_v7_');
    final dbFile = File('${tempDir.path}/gym_test_v6.db');

    try {
      final v6Executor = NativeDatabase(dbFile);
      await v6Executor.ensureOpen(_DummyUserV6());

      await v6Executor.runCustom('''
        CREATE TABLE members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          photo_path TEXT,
          gender TEXT,
          age INTEGER,
          weight_kg REAL,
          height_cm REAL,
          is_suspended INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'active',
          search_name TEXT,
          created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
          updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
        );
      ''');
      await v6Executor.runCustom('''
        CREATE TABLE payments (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL REFERENCES members (id), subscription_id INTEGER, period_id INTEGER, installment_id INTEGER, amount REAL NOT NULL, paid_at INTEGER NOT NULL DEFAULT 0, payment_method TEXT NOT NULL DEFAULT 'cash', notes TEXT);
      ''');
      await v6Executor.runCustom('''
        CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount REAL NOT NULL, category TEXT NOT NULL, date INTEGER NOT NULL, notes TEXT);
      ''');

      await v6Executor.runCustom('PRAGMA user_version = 6;');
      await v6Executor.runCustom("INSERT INTO members (id, name, phone) VALUES (1, 'عضو تجريبي', '01011112222');");
      await v6Executor.runCustom("INSERT INTO payments (id, member_id, amount) VALUES (1, 1, 150.0);");
      await v6Executor.runCustom("INSERT INTO expenses (id, title, amount, category, date) VALUES (1, 'كهرباء', 50.0, 'electricity', 0);");
      await v6Executor.close();

      // Open database with AppDatabase (which will trigger onUpgrade from 6 to 7)
      final v7Executor = NativeDatabase(dbFile);
      final db = AppDatabase(v7Executor);

      final p = await (db.select(db.payments)..where((p) => p.id.equals(1))).getSingle();
      expect(p.amount, 150.0);
      expect(p.voidedAt, isNull);
      expect(p.voidReason, isNull);

      final e = await (db.select(db.expenses)..where((e) => e.id.equals(1))).getSingle();
      expect(e.title, 'كهرباء');
      expect(e.voidedAt, isNull);
      expect(e.paymentMethod, isNull);

      await db.close();
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test('migration from v7 to v8 adds track_attendance columns and attendance_logs table', () async {
    final tempDir = await Directory.systemTemp.createTemp('gym_migration_test_');
    final dbFile = File('${tempDir.path}/gym_test_v7.db');

    try {
      final v7Executor = NativeDatabase(dbFile);
      await v7Executor.ensureOpen(_DummyUserV7());

      // Create v7 schema tables
      await v7Executor.runCustom('''
        CREATE TABLE packages (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL NOT NULL, duration_value INTEGER NOT NULL, duration_unit TEXT NOT NULL DEFAULT 'days', duration_in_days INTEGER NOT NULL, is_active INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL);
      ''');
      await v7Executor.runCustom('''
        CREATE TABLE subscriptions (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL, package_id INTEGER, package_name_snapshot TEXT NOT NULL, price_snapshot REAL NOT NULL, start_date INTEGER NOT NULL, end_date INTEGER NOT NULL, is_renewal INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'active', is_paused INTEGER NOT NULL DEFAULT 0, paused_at INTEGER, pause_reason TEXT, total_paused_days INTEGER NOT NULL DEFAULT 0, amount_paid REAL NOT NULL DEFAULT 0.0, created_at INTEGER NOT NULL);
      ''');

      await v7Executor.runCustom('PRAGMA user_version = 7;');
      await v7Executor.runCustom("INSERT INTO packages (id, name, price, duration_value, duration_in_days, created_at) VALUES (1, 'باقة شهرية', 300.0, 30, 30, 0);");
      await v7Executor.runCustom("INSERT INTO subscriptions (id, member_id, package_id, package_name_snapshot, price_snapshot, start_date, end_date, created_at) VALUES (1, 1, 1, 'باقة شهرية', 300.0, 0, 1000, 0);");
      await v7Executor.close();

      // Open database with AppDatabase (which will trigger onUpgrade from 7 to 8)
      final v8Executor = NativeDatabase(dbFile);
      final db = AppDatabase(v8Executor);

      final pkg = await (db.select(db.packages)..where((p) => p.id.equals(1))).getSingle();
      expect(pkg.trackAttendance, false);

      final sub = await (db.select(db.subscriptions)..where((s) => s.id.equals(1))).getSingle();
      expect(sub.trackAttendance, false);

      final logs = await db.select(db.attendanceLogs).get();
      expect(logs, isEmpty);

      await db.close();
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test('migration from v8 to v9 adds is_pay_as_you_go columns to packages and subscriptions', () async {
    final tempDir = await Directory.systemTemp.createTemp('gym_migration_test_v8_v9_');
    final dbFile = File('${tempDir.path}/gym_test_v8.db');

    try {
      final v8Executor = NativeDatabase(dbFile);
      await v8Executor.ensureOpen(_DummyUserV8());

      // Create v8 schema tables without is_pay_as_you_go
      await v8Executor.runCustom('''
        CREATE TABLE packages (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL NOT NULL, duration_value INTEGER NOT NULL, duration_unit TEXT NOT NULL DEFAULT 'days', duration_in_days INTEGER NOT NULL, track_attendance INTEGER NOT NULL DEFAULT 0, is_active INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL);
      ''');
      await v8Executor.runCustom('''
        CREATE TABLE subscriptions (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL, package_id INTEGER, package_name_snapshot TEXT NOT NULL, price_snapshot REAL NOT NULL, start_date INTEGER NOT NULL, end_date INTEGER NOT NULL, is_renewal INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'active', is_paused INTEGER NOT NULL DEFAULT 0, paused_at INTEGER, pause_reason TEXT, total_paused_days INTEGER NOT NULL DEFAULT 0, amount_paid REAL NOT NULL DEFAULT 0.0, track_attendance INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL);
      ''');

      await v8Executor.runCustom('PRAGMA user_version = 8;');
      await v8Executor.runCustom("INSERT INTO packages (id, name, price, duration_value, duration_in_days, created_at) VALUES (1, 'باقة شهرية', 300.0, 30, 30, 0);");
      await v8Executor.runCustom("INSERT INTO subscriptions (id, member_id, package_id, package_name_snapshot, price_snapshot, start_date, end_date, created_at) VALUES (1, 1, 1, 'باقة شهرية', 300.0, 0, 1000, 0);");
      await v8Executor.close();

      // Open database with AppDatabase (which will trigger onUpgrade from 8 to 9)
      final v9Executor = NativeDatabase(dbFile);
      final db = AppDatabase(v9Executor);

      final pkg = await (db.select(db.packages)..where((p) => p.id.equals(1))).getSingle();
      expect(pkg.isPayAsYouGo, false);

      final sub = await (db.select(db.subscriptions)..where((s) => s.id.equals(1))).getSingle();
      expect(sub.isPayAsYouGo, false);

      // Verify we can insert with isPayAsYouGo = true
      await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'باقة يومية حسب الاستخدام',
          price: 25.0,
          durationValue: const Value(1),
          durationInDays: 1,
          createdAt: Value(DateTime.now()),
          isPayAsYouGo: const Value(true),
        ),
      );

      final newPkg = await (db.select(db.packages)..where((p) => p.id.equals(2))).getSingle();
      expect(newPkg.isPayAsYouGo, true);

      await db.close();
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}

class _DummyUserV8 extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 8;
}

class _DummyUserV7 extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 7;
}

class _DummyUserV6 extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 6;
}

class _DummyUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 5;
}

