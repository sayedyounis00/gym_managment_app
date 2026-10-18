import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/memberships_dao.dart';
import 'package:gym_managment_app/features/memberships/data/datasources/memberships_local_datasource.dart';
import 'package:gym_managment_app/features/memberships/data/repositories/memberships_repository_impl.dart';
import 'package:gym_managment_app/features/memberships/domain/entities/membership_package.dart';
import 'package:gym_managment_app/features/memberships/domain/repositories/memberships_repository.dart';

void main() {
  late AppDatabase db;
  late MembershipsDao dao;
  late MembershipsRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = MembershipsDao(db);
    final ds = MembershipsLocalDataSourceImpl(dao: dao);
    repository = MembershipsRepositoryImpl(localDataSource: ds);
  });

  tearDown(() async {
    await db.close();
  });

  group('Packages CRUD and Constraints', () {
    test('savePackage inserts new package and retrieves it', () async {
      final pkg = MembershipPackage(
        id: 0,
        name: 'باقة شهرية',
        price: 450,
        durationValue: 1,
        durationUnit: 'months',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final result = await repository.savePackage(pkg);
      expect(result.isRight(), isTrue);

      final id = result.getOrElse((_) => 0);
      expect(id, isPositive);

      final fetchResult = await repository.getPackageById(id);
      expect(fetchResult.isRight(), isTrue);
      fetchResult.fold(
        (_) => fail('should have found package'),
        (saved) {
          expect(saved.name, 'باقة شهرية');
          expect(saved.price, 450);
          expect(saved.durationValue, 1);
          expect(saved.durationUnit, 'months');
          expect(saved.isActive, isTrue);
        },
      );
    });

    test('togglePackageActive updates package status', () async {
      final pkg = MembershipPackage(
        id: 0,
        name: 'باقة سنوية',
        price: 4000,
        durationValue: 12,
        durationUnit: 'months',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final id = (await repository.savePackage(pkg)).getOrElse((_) => 0);
      await repository.setPackageActive(id, false);

      final updated = (await repository.getPackageById(id)).getOrElse((_) => throw Exception());
      expect(updated.isActive, isFalse);

      final activeOnlyList = (await repository.getPackages(activeOnly: true)).getOrElse((_) => []);
      expect(activeOnlyList.any((p) => p.id == id), isFalse);

      final allList = (await repository.getPackages(activeOnly: false)).getOrElse((_) => []);
      expect(allList.any((p) => p.id == id), isTrue);
    });

    test('cannot delete package that has subscriptions', () async {
      // Create member
      final memberId = await db.into(db.members).insert(
        MembersCompanion.insert(name: 'علي حسن', phone: '01011112222'),
      );

      // Create package
      final pkg = MembershipPackage(
        id: 0,
        name: 'باقة 3 شهور',
        price: 1200,
        durationValue: 3,
        durationUnit: 'months',
        createdAt: DateTime.now(),
      );
      final pkgId = (await repository.savePackage(pkg)).getOrElse((_) => 0);

      // Renew / create subscription with this package
      await repository.renewSubscription(
        RenewParams(
          memberId: memberId,
          packageId: pkgId,
          packageName: 'باقة 3 شهور',
          price: 1200,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 4, 1),
          amountPaid: 1200,
          paymentMethod: 'cash',
        ),
      );

      // Attempt to delete package
      final deleteResult = await repository.deletePackage(pkgId);
      expect(deleteResult.isLeft(), isTrue);

      // Package must still exist
      final check = await repository.getPackageById(pkgId);
      expect(check.isRight(), isTrue);
    });
  });

  group('Atomic Renewal and Payments', () {
    test('renewSubscription atomically creates subscription and payment, and updates member', () async {
      final memberId = await db.into(db.members).insert(
        MembersCompanion.insert(name: 'سارة أحمد', phone: '01033334444'),
      );

      final pkgId = await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'باقة اللياقة',
          price: 600,
          durationValue: const drift.Value(30),
          durationUnit: const drift.Value('days'),
        ),
      );

      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31);

      final renewResult = await repository.renewSubscription(
        RenewParams(
          memberId: memberId,
          packageId: pkgId,
          packageName: 'باقة اللياقة',
          price: 600,
          startDate: start,
          endDate: end,
          amountPaid: 400, // Partial payment
          paymentMethod: 'wallet',
        ),
      );

      expect(renewResult.isRight(), isTrue);
      final subId = renewResult.getOrElse((_) => 0);
      expect(subId, isPositive);

      // Check subscription
      final currentSub = (await repository.getCurrentSubscription(memberId)).getOrElse((_) => null);
      expect(currentSub, isNotNull);
      expect(currentSub!.id, subId);
      expect(currentSub.packageNameSnapshot, 'باقة اللياقة');
      expect(currentSub.priceSnapshot, 600);
      expect(currentSub.amountPaid, 400);
      expect(currentSub.remainingAmount, 200);

      // Check payment was inserted in database
      final payments = await (db.select(db.payments)..where((p) => p.memberId.equals(memberId))).get();
      expect(payments.length, 1);
      expect(payments.first.amount, 400);
      expect(payments.first.paymentMethod, 'wallet');
      expect(payments.first.subscriptionId, subId);

      // Check member status updated
      final member = await (db.select(db.members)..where((m) => m.id.equals(memberId))).getSingle();
      expect(member.status, 'active');
      expect(member.isSuspended, isFalse);
    });

    test('renewing marks previous active subscription as expired', () async {
      final memberId = await db.into(db.members).insert(
        MembersCompanion.insert(name: 'محمد خالد', phone: '01055556666'),
      );

      final pkgId = await db.into(db.packages).insert(
        PackagesCompanion.insert(name: 'باقة شهرية', price: 300),
      );

      // First subscription
      final sub1Id = (await repository.renewSubscription(
        RenewParams(
          memberId: memberId,
          packageId: pkgId,
          packageName: 'باقة شهرية',
          price: 300,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 2, 1),
          amountPaid: 300,
          paymentMethod: 'cash',
        ),
      )).getOrElse((_) => 0);

      // Second subscription (renewal)
      final sub2Id = (await repository.renewSubscription(
        RenewParams(
          memberId: memberId,
          packageId: pkgId,
          packageName: 'باقة شهرية',
          price: 300,
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 3, 1),
          amountPaid: 300,
          paymentMethod: 'cash',
          previousSubscriptionId: sub1Id,
        ),
      )).getOrElse((_) => 0);

      expect(sub2Id, isNot(sub1Id));

      // Sub 1 should now be expired
      final allSubs = await (db.select(db.subscriptions)..where((s) => s.memberId.equals(memberId))).get();
      final oldSub = allSubs.firstWhere((s) => s.id == sub1Id);
      final newSub = allSubs.firstWhere((s) => s.id == sub2Id);

      expect(oldSub.status, 'expired');
      expect(newSub.status, 'active');
    });
  });

  group('Atomic Pause and Resume in Database', () {
    test('pause and resume correctly updates database rows and dates', () async {
      final memberId = await db.into(db.members).insert(
        MembersCompanion.insert(name: 'يوسف رامي', phone: '01077778888'),
      );

      final pkgId = await db.into(db.packages).insert(
        PackagesCompanion.insert(name: 'باقة شهرية', price: 500),
      );

      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 6, 1);

      await repository.renewSubscription(
        RenewParams(
          memberId: memberId,
          packageId: pkgId,
          packageName: 'باقة شهرية',
          price: 500,
          startDate: start,
          endDate: end,
          amountPaid: 500,
          paymentMethod: 'cash',
        ),
      );

      // Pause on 10th
      final pauseDate = DateTime(2026, 5, 10);
      final pauseRes = await repository.pauseSubscription(
        PauseParams(
          memberId: memberId,
          pauseDate: pauseDate,
          reason: 'ظروف عائلية',
        ),
      );
      expect(pauseRes.isRight(), isTrue);

      var sub = (await repository.getCurrentSubscription(memberId)).getOrElse((_) => null);
      expect(sub!.status, 'paused');
      expect(sub.pausedAt, pauseDate);
      expect(sub.pauseReason, 'ظروف عائلية');

      var member = await (db.select(db.members)..where((m) => m.id.equals(memberId))).getSingle();
      expect(member.isSuspended, isTrue);
      expect(member.status, 'paused');

      // Resume on 20th (10 days shifted)
      final resumeDate = DateTime(2026, 5, 20);
      final resumeRes = await repository.resumeSubscription(memberId, resumeDate);
      expect(resumeRes.isRight(), isTrue);

      sub = (await repository.getCurrentSubscription(memberId)).getOrElse((_) => null);
      expect(sub!.status, 'active');
      expect(sub.pausedAt, isNull);
      expect(sub.totalPausedDays, 10);
      expect(sub.endDate, DateTime(2026, 6, 11)); // shifted by 10 days!

      member = await (db.select(db.members)..where((m) => m.id.equals(memberId))).getSingle();
      expect(member.isSuspended, isFalse);
      expect(member.status, 'active');
    });
  });
}
