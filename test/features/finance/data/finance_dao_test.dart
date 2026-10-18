import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/finance_dao.dart';
import 'package:gym_managment_app/core/database/daos/payments_dao.dart';
import 'package:gym_managment_app/core/database/daos/expenses_dao.dart';

void main() {
  late AppDatabase db;
  late FinanceDao financeDao;
  late PaymentsDao paymentsDao;
  late ExpensesDao expensesDao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    financeDao = FinanceDao(db);
    paymentsDao = PaymentsDao(db);
    expensesDao = ExpensesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('FinanceDao returns correct monthly summary and excludes voided records', () async {
    final now = DateTime.now();

    final m1 = await db.into(db.members).insert(
      MembersCompanion.insert(name: 'أحمد علي', phone: '01011112222'),
    );

    // Insert 2 payments
    await paymentsDao.insertPayment(
      PaymentsCompanion.insert(
        memberId: m1,
        amount: 200.0,
        paidAt: Value(now),
        paymentMethod: const Value('cash'),
      ),
    );

    final p2 = await paymentsDao.insertPayment(
      PaymentsCompanion.insert(
        memberId: m1,
        amount: 100.0,
        paidAt: Value(now),
        paymentMethod: const Value('transfer'),
      ),
    );

    // Insert 2 expenses
    await expensesDao.insertExpense(
      ExpensesCompanion.insert(
        title: 'فاتورة الكهرباء',
        category: const Value('electricity'),
        amount: 80.0,
        date: Value(now),
      ),
    );

    final e2 = await expensesDao.insertExpense(
      ExpensesCompanion.insert(
        title: 'صيانة جهاز',
        category: const Value('maintenance'),
        amount: 50.0,
        date: Value(now),
      ),
    );

    // Check summary before voiding
    var summary = await financeDao.getMonthlySummary(now);
    expect(summary.revenue, 300.0);
    expect(summary.expenses, 130.0);
    expect(summary.net, 170.0);

    // Void one payment (p2 = 100) and one expense (e2 = 50)
    await paymentsDao.voidPayment(p2, reason: 'خطأ في المبلغ');
    await expensesDao.voidExpense(e2);

    summary = await financeDao.getMonthlySummary(now);
    expect(summary.revenue, 200.0);
    expect(summary.expenses, 80.0);
    expect(summary.net, 120.0);
  });

  test('FinanceDao watchLedger generates correctly ordered and tagged unified entries', () async {
    final now = DateTime.now();

    final m1 = await db.into(db.members).insert(
      MembersCompanion.insert(name: 'محمد خالد', phone: '01033334444'),
    );

    await paymentsDao.insertPayment(
      PaymentsCompanion.insert(
        memberId: m1,
        amount: 500.0,
        paidAt: Value(now.subtract(const Duration(hours: 2))),
        paymentMethod: const Value('wallet'),
      ),
    );

    await expensesDao.insertExpense(
      ExpensesCompanion.insert(
        title: 'إيجار الصالة',
        category: const Value('rent'),
        amount: 250.0,
        date: Value(now.subtract(const Duration(hours: 1))),
      ),
    );

    final entries = await financeDao.watchLedger(typeFilter: 'all').first;
    expect(entries.length, 2);

    // First entry should be the more recent (expense: 1 hour ago vs payment: 2 hours ago)
    expect(entries[0].type, 'expense');
    expect(entries[0].title, 'إيجار الصالة');
    expect(entries[0].amount, 250.0);

    expect(entries[1].type, 'income');
    expect(entries[1].title, 'محمد خالد');
    expect(entries[1].amount, 500.0);
    expect(entries[1].method, 'wallet');
  });

  test('FinanceDao getMembersWithBalance returns members with outstanding amounts', () async {
    final now = DateTime.now();

    final m1 = await db.into(db.members).insert(
      MembersCompanion.insert(name: 'كريم محمود', phone: '01055556666'),
    );

    final subId = await db.into(db.subscriptions).insert(
      SubscriptionsCompanion.insert(
        memberId: m1,
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        packageNameSnapshot: const Value('باقة شهرية'),
        priceSnapshot: const Value(300.0),
      ),
    );

    final periodId = await db.into(db.subscriptionPeriods).insert(
      SubscriptionPeriodsCompanion.insert(
        subscriptionId: subId,
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        amountDue: 300.0,
      ),
    );

    // Record partial payment of 100
    await paymentsDao.insertPayment(
      PaymentsCompanion.insert(
        memberId: m1,
        subscriptionId: Value(subId),
        periodId: Value(periodId),
        amount: 100.0,
        paidAt: Value(now),
      ),
    );

    final debtors = await financeDao.getMembersWithBalance();
    expect(debtors.length, 1);
    expect(debtors.first.memberId, m1);
    expect(debtors.first.memberName, 'كريم محمود');
    expect(debtors.first.totalDue, 300.0);
    expect(debtors.first.totalPaid, 100.0);
    expect(debtors.first.remaining, 200.0);
  });
}
