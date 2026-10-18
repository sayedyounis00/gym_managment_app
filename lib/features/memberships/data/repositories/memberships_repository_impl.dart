import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../../domain/entities/membership_package.dart';
import '../../domain/entities/subscription.dart' as domain;
import '../../domain/repositories/memberships_repository.dart';
import '../datasources/memberships_local_datasource.dart';
import '../models/package_model.dart';
import '../models/subscription_model.dart';

class MembershipsRepositoryImpl implements MembershipsRepository {
  final MembershipsLocalDataSource localDataSource;

  MembershipsRepositoryImpl({required this.localDataSource});

  @override
  Stream<List<MembershipPackage>> watchPackages({bool activeOnly = false}) {
    return localDataSource
        .watchPackages(activeOnly: activeOnly)
        .map((rows) => rows.map(PackageModel.fromDrift).toList());
  }

  @override
  Future<Either<Failure, List<MembershipPackage>>> getPackages({bool activeOnly = false}) async {
    try {
      final rows = await localDataSource.getPackages(activeOnly: activeOnly);
      return Right(rows.map(PackageModel.fromDrift).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل تحميل قائمة الباقات: $e'));
    }
  }

  @override
  Future<Either<Failure, MembershipPackage>> getPackageById(int id) async {
    try {
      final row = await localDataSource.getPackageById(id);
      if (row == null) {
        return const Left(DatabaseFailure('الباقة غير موجودة'));
      }
      return Right(PackageModel.fromDrift(row));
    } catch (e) {
      return Left(DatabaseFailure('فشل استرجاع الباقة: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> savePackage(MembershipPackage package) async {
    try {
      if (package.id > 0) {
        final companion = PackageModel.toCompanion(package);
        final success = await localDataSource.updatePackage(companion);
        if (success) {
          return Right(package.id);
        } else {
          return const Left(DatabaseFailure('فشل تحديث بيانات الباقة'));
        }
      } else {
        final companion = PackageModel.toCompanion(package);
        final id = await localDataSource.insertPackage(companion);
        return Right(id);
      }
    } catch (e) {
      return Left(DatabaseFailure('فشل حفظ الباقة: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setPackageActive(int id, bool isActive) async {
    try {
      await localDataSource.setPackageActive(id, isActive);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('فشل تغيير حالة الباقة: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePackage(int id) async {
    try {
      final hasSubs = await localDataSource.hasSubscriptions(id);
      if (hasSubs) {
        return const Left(DatabaseFailure(
          'لا يمكن حذف باقة مرتبطة باشتراكات، يمكنك إلغاء تفعيلها بدلاً من ذلك لحفظ السجلات',
        ));
      }
      await localDataSource.deletePackage(id);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('فشل حذف الباقة: $e'));
    }
  }

  @override
  Future<Either<Failure, domain.Subscription?>> getCurrentSubscription(int memberId) async {
    try {
      final row = await localDataSource.getLatestSubscription(memberId);
      if (row == null) return const Right(null);
      return Right(SubscriptionModel.fromDrift(row));
    } catch (e) {
      return Left(DatabaseFailure('فشل استرجاع الاشتراك الحالي: $e'));
    }
  }

  @override
  Stream<domain.Subscription?> watchCurrentSubscription(int memberId) {
    return localDataSource
        .watchLatestSubscription(memberId)
        .map((row) => row != null ? SubscriptionModel.fromDrift(row) : null);
  }

  @override
  Future<Either<Failure, List<domain.Subscription>>> getMemberSubscriptions(int memberId) async {
    try {
      final rows = await localDataSource.getMemberSubscriptions(memberId);
      return Right(rows.map(SubscriptionModel.fromDrift).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل استرجاع سجل الاشتراكات: $e'));
    }
  }

  @override
  Stream<List<domain.Subscription>> watchMemberSubscriptions(int memberId) {
    return localDataSource
        .watchMemberSubscriptions(memberId)
        .map((rows) => rows.map(SubscriptionModel.fromDrift).toList());
  }

  @override
  Future<Either<Failure, int>> renewSubscription(RenewParams params) async {
    try {
      final subCompanion = SubscriptionsCompanion(
        memberId: Value(params.memberId),
        packageId: Value(params.packageId),
        packageNameSnapshot: Value(params.packageName),
        priceSnapshot: Value(params.price),
        startDate: Value(params.startDate),
        endDate: Value(params.endDate),
        isRenewal: Value(params.previousSubscriptionId != null),
        status: const Value('active'),
        amountPaid: Value(params.amountPaid),
        createdAt: Value(DateTime.now()),
      );

      PaymentsCompanion? paymentCompanion;
      if (params.amountPaid > 0) {
        paymentCompanion = PaymentsCompanion(
          memberId: Value(params.memberId),
          amount: Value(params.amountPaid),
          paidAt: Value(DateTime.now()),
          paymentMethod: Value(params.paymentMethod),
          notes: Value('تجديد باقة: ${params.packageName}'),
        );
      }

      final newSubId = await localDataSource.atomicRenew(
        subscription: subCompanion,
        payment: paymentCompanion,
        previousSubscriptionId: params.previousSubscriptionId,
      );

      return Right(newSubId);
    } catch (e) {
      return Left(DatabaseFailure('فشل تجديد الاشتراك: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> pauseSubscription(PauseParams params) async {
    try {
      final success = await localDataSource.atomicPause(
        memberId: params.memberId,
        pauseDate: params.pauseDate,
        reason: params.reason,
      );
      if (success) {
        return const Right(unit);
      } else {
        return const Left(DatabaseFailure('لا يوجد اشتراك نشط للإيقاف'));
      }
    } catch (e) {
      return Left(DatabaseFailure('فشل إيقاف الاشتراك: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> resumeSubscription(int memberId, DateTime resumeDate) async {
    try {
      final success = await localDataSource.atomicResume(
        memberId: memberId,
        resumeDate: resumeDate,
      );
      if (success) {
        return const Right(unit);
      } else {
        return const Left(DatabaseFailure('لا يوجد اشتراك موقوف للاستئناف'));
      }
    } catch (e) {
      return Left(DatabaseFailure('فشل استئناف الاشتراك: $e'));
    }
  }

  @override
  Stream<List<domain.Subscription>> watchExpiringSubscriptions({
    required DateTime now,
    int windowDays = 3,
  }) {
    return localDataSource
        .watchExpiringSubscriptions(now: now, windowDays: windowDays)
        .map((rows) => rows.map(SubscriptionModel.fromDrift).toList());
  }

  @override
  Future<Either<Failure, int>> refreshExpiredStatuses(DateTime now) async {
    try {
      final count = await localDataSource.refreshExpiredStatuses(now);
      return Right(count);
    } catch (e) {
      return Left(DatabaseFailure('فشل تحديث الاشتراكات المنتهية: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSubscription(int subscriptionId) async {
    try {
      await localDataSource.deleteSubscription(subscriptionId);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('فشل حذف الاشتراك: $e'));
    }
  }
}
