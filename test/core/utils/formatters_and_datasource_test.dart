import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/dashboard_dao.dart';
import 'package:gym_managment_app/core/utils/currency_formatter.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'package:gym_managment_app/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  group('CurrencyFormatter Tests', () {
    test('formats regular currency with symbol', () {
      final formatted = CurrencyFormatter.format(1500.50);
      expect(formatted, contains('1,500.50'));
      expect(formatted, contains('ج.م'));
    });

    test('formats compact currency with symbol', () {
      final compact = CurrencyFormatter.formatCompact(25000);
      expect(compact, contains('ج.م'));
      expect(compact, contains('25'));
    });
  });

  group('AppDateUtils Tests', () {
    test('formats greeting date for Arabic locale', () {
      final testDate = DateTime(2026, 10, 18);
      final formatted = AppDateUtils.formatGreetingDate(testDate, locale: 'ar');
      expect(formatted.isNotEmpty, isTrue);
    });

    test('formats short date correctly', () {
      final testDate = DateTime(2026, 10, 18);
      final formatted = AppDateUtils.formatShortDate(testDate, locale: 'ar');
      expect(formatted, contains('2026'));
      expect(formatted, contains('18'));
    });
  });

  group('DashboardLocalDataSource Parallel Query Tests', () {
    late AppDatabase db;
    late DashboardDao dao;
    late DashboardLocalDataSourceImpl datasource;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.dashboardDao;
      datasource = DashboardLocalDataSourceImpl(dashboardDao: dao);
    });

    tearDown(() async {
      await db.close();
    });

    test('getSummary executes parallel queries and returns empty summary on empty db', () async {
      final summary = await datasource.getSummary(now: DateTime.now());
      expect(summary.activeMembersCount, equals(0));
      expect(summary.monthRevenue, equals(0.0));
      expect(summary.monthExpenses, equals(0.0));
      expect(summary.expiringSoon, isEmpty);
    });
  });
}
