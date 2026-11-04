import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/attendance_dao.dart';
import 'package:gym_managment_app/core/database/daos/members_dao.dart';
import 'package:gym_managment_app/core/database/daos/memberships_dao.dart';
import 'package:gym_managment_app/core/database/daos/payments_dao.dart';
import 'package:gym_managment_app/features/finance/data/repositories/payment_repository_impl.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/add_payment.dart';
import 'package:gym_managment_app/features/finance/presentation/cubit/add_payment/add_payment_cubit.dart';

void main() {
  late AppDatabase db;
  late MembersDao membersDao;
  late AttendanceDao attendanceDao;
  late MembershipsDao membershipsDao;
  late PaymentsDao paymentsDao;
  late AddPaymentCubit addPaymentCubit;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON;');
    membersDao = MembersDao(db);
    attendanceDao = AttendanceDao(db);
    membershipsDao = MembershipsDao(db);
    paymentsDao = PaymentsDao(db);

    final paymentRepo = PaymentRepositoryImpl(
      db: db,
      paymentsDao: paymentsDao,
      membersDao: membersDao,
    );

    addPaymentCubit = AddPaymentCubit(
      db: db,
      membersDao: membersDao,
      addPaymentUseCase: AddPayment(paymentRepo),
    );
  });

  tearDown(() async {
    await addPaymentCubit.close();
    await db.close();
  });

  group('AddPaymentCubit Pay-As-You-Go Tests', () {
    test('Correctly calculates dueAmount and remaining for pay-as-you-go subscription with attendances', () async {
      // 1. Create a pay-as-you-go package with daily rate 70 EGP
      final pkgId = await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'باقه شغاله',
          price: 70.0,
          durationInDays: 1,
          isPayAsYouGo: const drift.Value(true),
          trackAttendance: const drift.Value(true),
        ),
      );

      // 2. Add member
      final memberId = await membersDao.insertMember(
        MembersCompanion.insert(
          name: 'السيد خالد السنونس',
          phone: '01000000005',
        ),
      );

      // 3. Create active subscription with initial payment of 70
      final subId = await membershipsDao.atomicRenew(
        subscription: SubscriptionsCompanion.insert(
          memberId: memberId,
          packageId: drift.Value(pkgId),
          packageNameSnapshot: const drift.Value('باقه شغاله'),
          priceSnapshot: const drift.Value(70.0),
          startDate: DateTime.now(),
          endDate: DateTime(2099, 12, 31),
          status: const drift.Value('active'),
          amountPaid: const drift.Value(70.0),
          isPayAsYouGo: const drift.Value(true),
          trackAttendance: const drift.Value(true),
        ),
        payment: PaymentsCompanion.insert(
          memberId: memberId,
          amount: 70.0,
          paidAt: drift.Value(DateTime.now()),
          paymentMethod: const drift.Value('cash'),
          notes: const drift.Value('اشتراك أول يوم'),
        ),
      );

      // 4. Member attends 2 days
      await attendanceDao.markAttendance(memberId, subId, DateTime.now().subtract(const Duration(days: 1)));
      await attendanceDao.markAttendance(memberId, subId, DateTime.now());

      // 5. Select member in AddPaymentCubit
      await addPaymentCubit.selectMember(memberId);

      // 6. Verify due, paid, remaining, and label
      final options = addPaymentCubit.state.periodOptions;
      expect(options.length, equals(1));
      final option = options.first;

      expect(option.isPayAsYouGo, isTrue);
      expect(option.dueAmount, equals(140.0), reason: '2 days * 70 EGP daily rate = 140 EGP');
      expect(option.paidAmount, equals(70.0), reason: 'Initial payment was 70 EGP');
      expect(option.remaining, equals(70.0), reason: 'Member owes 140 - 70 = 70 EGP, NOT 0.0 EGP!');
      expect(addPaymentCubit.state.amount, equals(70.0), reason: 'Default amount prefilled should be 70 EGP');
      expect(option.label, contains('2 يوم'));

      // 7. Test submitting the remaining 70 EGP payment
      addPaymentCubit.setAmount(70.0);
      final success = await addPaymentCubit.submit();
      expect(success, isTrue);

      // 8. Re-select member and verify remaining is now 0.0
      await addPaymentCubit.selectMember(memberId);
      final updatedOption = addPaymentCubit.state.periodOptions.first;
      expect(updatedOption.paidAmount, equals(140.0));
      expect(updatedOption.remaining, equals(0.0));
    });
  });
}
