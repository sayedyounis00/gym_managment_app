import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../entities/membership_package.dart';
import '../entities/subscription.dart';

class RenewParams {
  final int memberId;
  final int packageId;
  final String packageName;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final double amountPaid;
  final String paymentMethod; // 'cash', 'transfer', 'wallet'
  final int? previousSubscriptionId;

  const RenewParams({
    required this.memberId,
    required this.packageId,
    required this.packageName,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.amountPaid,
    required this.paymentMethod,
    this.previousSubscriptionId,
  });
}

class PauseParams {
  final int memberId;
  final DateTime pauseDate;
  final String? reason;

  const PauseParams({
    required this.memberId,
    required this.pauseDate,
    this.reason,
  });
}

abstract class MembershipsRepository {
  // Packages
  Stream<List<MembershipPackage>> watchPackages({bool activeOnly = false});
  Future<Either<Failure, List<MembershipPackage>>> getPackages({bool activeOnly = false});
  Future<Either<Failure, MembershipPackage>> getPackageById(int id);
  Future<Either<Failure, int>> savePackage(MembershipPackage package);
  Future<Either<Failure, Unit>> setPackageActive(int id, bool isActive);
  Future<Either<Failure, Unit>> deletePackage(int id);

  // Subscriptions
  Future<Either<Failure, Subscription?>> getCurrentSubscription(int memberId);
  Stream<Subscription?> watchCurrentSubscription(int memberId);
  Future<Either<Failure, List<Subscription>>> getMemberSubscriptions(int memberId);
  Stream<List<Subscription>> watchMemberSubscriptions(int memberId);
  Future<Either<Failure, int>> renewSubscription(RenewParams params);
  Future<Either<Failure, Unit>> pauseSubscription(PauseParams params);
  Future<Either<Failure, Unit>> resumeSubscription(int memberId, DateTime resumeDate);
  Stream<List<Subscription>> watchExpiringSubscriptions({required DateTime now, int windowDays = 3});
  Future<Either<Failure, int>> refreshExpiredStatuses(DateTime now);
}
