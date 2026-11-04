import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/members_dao.dart';
import 'package:gym_managment_app/core/database/daos/memberships_dao.dart';
import 'package:gym_managment_app/core/database/daos/notes_dao.dart';
import 'package:gym_managment_app/core/services/image_storage_service.dart';
import 'package:gym_managment_app/features/members/data/repositories/members_repository_impl.dart';
import 'package:gym_managment_app/features/memberships/data/datasources/memberships_local_datasource.dart';
import 'package:gym_managment_app/features/memberships/data/repositories/memberships_repository_impl.dart';
import 'package:gym_managment_app/features/memberships/domain/entities/membership_package.dart';
import 'package:gym_managment_app/features/memberships/domain/repositories/memberships_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockImageStorageService extends Mock implements ImageStorageService {}

void main() {
  late AppDatabase db;
  late MembersDao membersDao;
  late NotesDao notesDao;
  late MembershipsDao membershipsDao;
  late MembershipsRepository membershipsRepo;
  late MembersRepositoryImpl membersRepo;
  late MockImageStorageService mockImageStorage;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON;');
    membersDao = MembersDao(db);
    notesDao = NotesDao(db);
    membershipsDao = MembershipsDao(db);
    mockImageStorage = MockImageStorageService();

    final membershipsDs = MembershipsLocalDataSourceImpl(dao: membershipsDao);
    membershipsRepo = MembershipsRepositoryImpl(localDataSource: membershipsDs);

    membersRepo = MembersRepositoryImpl(
      membersDao: membersDao,
      notesDao: notesDao,
      imageStorageService: mockImageStorage,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Plan Price Isolation Tests', () {
    test('Updating package price does not affect existing active subscriptions', () async {
      // 1. Create a package with price 100
      final initialPkg = MembershipPackage(
        id: 0,
        name: 'باقة شهرية',
        price: 100.0,
        durationValue: 30,
        durationUnit: 'days',
        isActive: true,
        createdAt: DateTime.now(),
      );
      final pkgId = (await membershipsRepo.savePackage(initialPkg)).getOrElse((_) => 0);

      // 2. Add a member
      final memberId = await membersDao.insertMember(
        MembersCompanion.insert(
          name: 'محمد علي',
          phone: '01000000001',
        ),
      );

      // 3. Member subscribes to package at initial price 100 and pays 100 in full
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 30));
      await membershipsRepo.renewSubscription(
        RenewParams(
          memberId: memberId,
          packageName: 'باقة شهرية',
          packageId: pkgId,
          price: 100.0,
          startDate: startDate,
          endDate: endDate,
          amountPaid: 100.0,
          paymentMethod: 'cash',
        ),
      );

      // Verify initial subscription details
      final initialHistory = (await membersRepo.getMemberSubscriptions(memberId)).getOrElse((_) => []);
      expect(initialHistory.length, equals(1));
      expect(initialHistory.first.price, equals(100.0));
      expect(initialHistory.first.paidAmount, equals(100.0));
      expect(initialHistory.first.remainingAmount, equals(0.0));

      // 4. Admin updates package price to 150
      final updatedPkg = initialPkg.copyWith(id: pkgId, price: 150.0);
      await membershipsRepo.savePackage(updatedPkg);

      // 5. Existing member's subscription must remain 100 with 0 balance
      final updatedHistory = (await membersRepo.getMemberSubscriptions(memberId)).getOrElse((_) => []);
      expect(updatedHistory.length, equals(1));
      expect(updatedHistory.first.price, equals(100.0), reason: 'Existing subscription price should stay 100');
      expect(updatedHistory.first.paidAmount, equals(100.0));
      expect(updatedHistory.first.remainingAmount, equals(0.0), reason: 'Member should not owe 50 after package price increase');

      // 6. When the member renews, the renewal subscription gets the new price 150
      final renewStartDate = endDate.add(const Duration(days: 1));
      final renewEndDate = renewStartDate.add(const Duration(days: 30));
      final renewResult = await membershipsRepo.renewSubscription(
        RenewParams(
          memberId: memberId,
          packageName: 'باقة شهرية',
          packageId: pkgId,
          price: 150.0,
          startDate: renewStartDate,
          endDate: renewEndDate,
          amountPaid: 150.0,
          paymentMethod: 'cash',
          previousSubscriptionId: updatedHistory.first.id,
        ),
      );
      expect(renewResult.isRight(), isTrue);

      // 7. Verify member now has two subscriptions: old one at 100, new one at 150
      final postRenewHistory = (await membersRepo.getMemberSubscriptions(memberId)).getOrElse((_) => []);
      expect(postRenewHistory.length, equals(2));

      final activeSub = postRenewHistory.firstWhere((s) => s.id == renewResult.getOrElse((_) => 0));
      final oldSub = postRenewHistory.firstWhere((s) => s.id == initialHistory.first.id);

      expect(activeSub.price, equals(150.0));
      expect(activeSub.paidAmount, equals(150.0));
      expect(activeSub.remainingAmount, equals(0.0));

      expect(oldSub.price, equals(100.0));
      expect(oldSub.paidAmount, equals(100.0));
      expect(oldSub.remainingAmount, equals(0.0));
    });

    test('Partially paid subscription retains original price and outstanding balance', () async {
      // Create package with price 200
      final pkg = MembershipPackage(
        id: 0,
        name: 'باقة شهرين',
        price: 200.0,
        durationValue: 60,
        durationUnit: 'days',
        isActive: true,
        createdAt: DateTime.now(),
      );
      final pkgId = (await membershipsRepo.savePackage(pkg)).getOrElse((_) => 0);

      final memberId = await membersDao.insertMember(
        MembersCompanion.insert(
          name: 'سارة أحمد',
          phone: '01000000002',
        ),
      );

      // Subscribes at 200, pays 120 (remaining 80)
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 60));
      await membershipsRepo.renewSubscription(
        RenewParams(
          memberId: memberId,
          packageName: 'باقة شهرين',
          packageId: pkgId,
          price: 200.0,
          startDate: startDate,
          endDate: endDate,
          amountPaid: 120.0,
          paymentMethod: 'cash',
        ),
      );

      // Admin increases price to 250
      await membershipsRepo.savePackage(pkg.copyWith(id: pkgId, price: 250.0));

      // Member should still have total price 200 and remaining 80
      final history = (await membersRepo.getMemberSubscriptions(memberId)).getOrElse((_) => []);
      expect(history.length, equals(1));
      expect(history.first.price, equals(200.0));
      expect(history.first.paidAmount, equals(120.0));
      expect(history.first.remainingAmount, equals(80.0));
    });

    test('atomicRenew populates priceSnapshot and packageNameSnapshot defensively', () async {
      final pkgId = await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'باقة خاصة',
          price: 300.0,
          durationInDays: 30,
        ),
      );

      final memberId = await membersDao.insertMember(
        MembersCompanion.insert(
          name: 'خالد عمر',
          phone: '01000000003',
        ),
      );

      // Insert subscription without priceSnapshot or packageNameSnapshot
      final subId = await membershipsDao.atomicRenew(
        subscription: SubscriptionsCompanion.insert(
          memberId: memberId,
          packageId: drift.Value(pkgId),
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
        ),
      );

      final insertedSub = await (db.select(db.subscriptions)..where((s) => s.id.equals(subId))).getSingle();
      expect(insertedSub.priceSnapshot, equals(300.0));
      expect(insertedSub.packageNameSnapshot, equals('باقة خاصة'));
    });
  });
}
