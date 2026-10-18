import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../entities/subscription.dart';
import '../repositories/memberships_repository.dart';

class GetMemberSubscriptions {
  final MembershipsRepository repository;

  GetMemberSubscriptions(this.repository);

  Future<Either<Failure, Subscription?>> getCurrent(int memberId) {
    return repository.getCurrentSubscription(memberId);
  }

  Stream<Subscription?> watchCurrent(int memberId) {
    return repository.watchCurrentSubscription(memberId);
  }

  Future<Either<Failure, List<Subscription>>> getHistory(int memberId) {
    return repository.getMemberSubscriptions(memberId);
  }

  Stream<List<Subscription>> watchHistory(int memberId) {
    return repository.watchMemberSubscriptions(memberId);
  }
}

class GetExpiringSubscriptions {
  final MembershipsRepository repository;

  GetExpiringSubscriptions(this.repository);

  Stream<List<Subscription>> watch({required DateTime now, int windowDays = 3}) {
    return repository.watchExpiringSubscriptions(now: now, windowDays: windowDays);
  }
}

class RefreshExpiredStatuses {
  final MembershipsRepository repository;

  RefreshExpiredStatuses(this.repository);

  Future<Either<Failure, int>> call(DateTime now) {
    return repository.refreshExpiredStatuses(now);
  }
}
