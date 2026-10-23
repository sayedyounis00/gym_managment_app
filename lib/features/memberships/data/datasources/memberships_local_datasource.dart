import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/memberships_dao.dart';

abstract class MembershipsLocalDataSource {
  Stream<List<Package>> watchPackages({bool activeOnly = false});
  Future<List<Package>> getPackages({bool activeOnly = false});
  Future<Package?> getPackageById(int id);
  Future<int> insertPackage(PackagesCompanion companion);
  Future<bool> updatePackage(PackagesCompanion companion);
  Future<int> setPackageActive(int id, bool isActive);
  Future<bool> hasSubscriptions(int packageId);
  Future<int> deletePackage(int id);

  Future<Subscription?> getLatestSubscription(int memberId);
  Stream<Subscription?> watchLatestSubscription(int memberId);
  Future<List<Subscription>> getMemberSubscriptions(int memberId);
  Stream<List<Subscription>> watchMemberSubscriptions(int memberId);

  Future<int> atomicRenew({
    required SubscriptionsCompanion subscription,
    PaymentsCompanion? payment,
    int? previousSubscriptionId,
  });

  Future<bool> atomicPause({
    required int memberId,
    required DateTime pauseDate,
    String? reason,
  });

  Future<bool> atomicResume({
    required int memberId,
    required DateTime resumeDate,
  });

  Stream<List<Subscription>> watchExpiringSubscriptions({
    required DateTime now,
    int windowDays = 3,
  });

  Future<int> refreshExpiredStatuses(DateTime now);
  Future<void> deleteSubscription(int subscriptionId);
  Future<void> endSubscription(int subscriptionId);
}

class MembershipsLocalDataSourceImpl implements MembershipsLocalDataSource {
  final MembershipsDao dao;

  MembershipsLocalDataSourceImpl({required this.dao});

  @override
  Stream<List<Package>> watchPackages({bool activeOnly = false}) =>
      dao.watchPackages(activeOnly: activeOnly);

  @override
  Future<List<Package>> getPackages({bool activeOnly = false}) =>
      dao.getAllPackages(activeOnly: activeOnly);

  @override
  Future<Package?> getPackageById(int id) => dao.getPackageById(id);

  @override
  Future<int> insertPackage(PackagesCompanion companion) =>
      dao.insertPackage(companion);

  @override
  Future<bool> updatePackage(PackagesCompanion companion) =>
      dao.updatePackage(companion);

  @override
  Future<int> setPackageActive(int id, bool isActive) =>
      dao.setPackageActive(id, isActive);

  @override
  Future<bool> hasSubscriptions(int packageId) =>
      dao.hasSubscriptions(packageId);

  @override
  Future<int> deletePackage(int id) => dao.deletePackage(id);

  @override
  Future<Subscription?> getLatestSubscription(int memberId) =>
      dao.getLatestSubscription(memberId);

  @override
  Stream<Subscription?> watchLatestSubscription(int memberId) =>
      dao.watchLatestSubscription(memberId);

  @override
  Future<List<Subscription>> getMemberSubscriptions(int memberId) =>
      dao.getMemberSubscriptions(memberId);

  @override
  Stream<List<Subscription>> watchMemberSubscriptions(int memberId) =>
      dao.watchMemberSubscriptions(memberId);

  @override
  Future<int> atomicRenew({
    required SubscriptionsCompanion subscription,
    PaymentsCompanion? payment,
    int? previousSubscriptionId,
  }) =>
      dao.atomicRenew(
        subscription: subscription,
        payment: payment,
        previousSubscriptionId: previousSubscriptionId,
      );

  @override
  Future<bool> atomicPause({
    required int memberId,
    required DateTime pauseDate,
    String? reason,
  }) =>
      dao.atomicPause(
        memberId: memberId,
        pauseDate: pauseDate,
        reason: reason,
      );

  @override
  Future<bool> atomicResume({
    required int memberId,
    required DateTime resumeDate,
  }) =>
      dao.atomicResume(
        memberId: memberId,
        resumeDate: resumeDate,
      );

  @override
  Stream<List<Subscription>> watchExpiringSubscriptions({
    required DateTime now,
    int windowDays = 3,
  }) =>
      dao.watchExpiringSubscriptions(now: now, windowDays: windowDays);

  @override
  Future<int> refreshExpiredStatuses(DateTime now) =>
      dao.refreshExpiredStatuses(now);

  @override
  Future<void> deleteSubscription(int subscriptionId) =>
      dao.deleteSubscription(subscriptionId);

  @override
  Future<void> endSubscription(int subscriptionId) =>
      dao.endSubscription(subscriptionId);
}
