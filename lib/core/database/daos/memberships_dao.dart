import 'package:drift/drift.dart';
import '../../utils/date_utils.dart';
import '../app_database.dart';
import '../tables/members_table.dart';
import '../tables/packages_table.dart';
import '../tables/payments_table.dart';
import '../tables/subscriptions_table.dart';

part 'memberships_dao.g.dart';

class MemberSubscriptionRow {
  final Subscription subscription;
  final Package? package;

  const MemberSubscriptionRow({
    required this.subscription,
    this.package,
  });
}

@DriftAccessor(tables: [
  Packages,
  Subscriptions,
  Members,
  Payments,
])
class MembershipsDao extends DatabaseAccessor<AppDatabase> with _$MembershipsDaoMixin {
  MembershipsDao(super.db);

  Stream<List<Package>> watchPackages({bool activeOnly = false}) {
    final query = select(packages);
    if (activeOnly) {
      query.where((p) => p.isActive.equals(true));
    }
    query.orderBy([(p) => OrderingTerm.desc(p.createdAt)]);
    return query.watch();
  }

  Future<List<Package>> getAllPackages({bool activeOnly = false}) {
    final query = select(packages);
    if (activeOnly) {
      query.where((p) => p.isActive.equals(true));
    }
    query.orderBy([(p) => OrderingTerm.desc(p.createdAt)]);
    return query.get();
  }

  Future<Package?> getPackageById(int id) {
    return (select(packages)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertPackage(PackagesCompanion companion) {
    return into(packages).insert(companion);
  }

  Future<bool> updatePackage(PackagesCompanion companion) {
    return update(packages).replace(companion);
  }

  Future<int> setPackageActive(int id, bool isActive) {
    return (update(packages)..where((p) => p.id.equals(id))).write(
      PackagesCompanion(isActive: Value(isActive)),
    );
  }

  Future<bool> hasSubscriptions(int packageId) async {
    final count = subscriptions.id.count();
    final query = selectOnly(subscriptions)
      ..addColumns([count])
      ..where(subscriptions.packageId.equals(packageId));
    final result = await query.map((r) => r.read(count)).getSingle();
    return (result ?? 0) > 0;
  }

  Future<int> deletePackage(int id) {
    return (delete(packages)..where((p) => p.id.equals(id))).go();
  }

  Future<Subscription?> getLatestSubscription(int memberId) {
    return (select(subscriptions)
          ..where((s) => s.memberId.equals(memberId))
          ..orderBy([(s) => OrderingTerm.desc(s.endDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<Subscription?> watchLatestSubscription(int memberId) {
    return (select(subscriptions)
          ..where((s) => s.memberId.equals(memberId))
          ..orderBy([(s) => OrderingTerm.desc(s.endDate)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<List<Subscription>> getMemberSubscriptions(int memberId) {
    return (select(subscriptions)
          ..where((s) => s.memberId.equals(memberId))
          ..orderBy([(s) => OrderingTerm.desc(s.startDate)]))
        .get();
  }

  Stream<List<Subscription>> watchMemberSubscriptions(int memberId) {
    return (select(subscriptions)
          ..where((s) => s.memberId.equals(memberId))
          ..orderBy([(s) => OrderingTerm.desc(s.startDate)]))
        .watch();
  }

  Future<int> atomicRenew({
    required SubscriptionsCompanion subscription,
    PaymentsCompanion? payment,
    int? previousSubscriptionId,
  }) {
    return transaction(() async {
      // 1. Mark previous active subscription as ended/expired if exists
      if (previousSubscriptionId != null) {
        await (update(subscriptions)..where((s) => s.id.equals(previousSubscriptionId)))
            .write(const SubscriptionsCompanion(status: Value('expired')));
      } else {
        // Also ensure any lingering active subscriptions for this member are ended
        final memberIdVal = subscription.memberId.value;
        await (update(subscriptions)
              ..where((s) => s.memberId.equals(memberIdVal) & s.status.equals('active')))
            .write(const SubscriptionsCompanion(status: Value('expired')));
      }

      // 2. Insert new subscription
      final newSubId = await into(subscriptions).insert(subscription);

      // 3. Insert payment row if payment provided
      if (payment != null) {
        final paymentWithSub = payment.copyWith(subscriptionId: Value(newSubId));
        await into(payments).insert(paymentWithSub);
      }

      // 4. Update member active status & un-suspend
      final memberId = subscription.memberId.value;
      await (update(members)..where((m) => m.id.equals(memberId))).write(
        MembersCompanion(
          isSuspended: const Value(false),
          status: const Value('active'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return newSubId;
    });
  }

  Future<bool> atomicPause({
    required int memberId,
    required DateTime pauseDate,
    String? reason,
  }) {
    return transaction(() async {
      final sub = await (select(subscriptions)
            ..where((s) => s.memberId.equals(memberId) & s.status.equals('active'))
            ..orderBy([(s) => OrderingTerm.desc(s.endDate)])
            ..limit(1))
          .getSingleOrNull();

      if (sub == null) return false;

      await (update(subscriptions)..where((s) => s.id.equals(sub.id))).write(
        SubscriptionsCompanion(
          status: const Value('paused'),
          pausedAt: Value(pauseDate),
          pauseReason: Value(reason),
        ),
      );

      await (update(members)..where((m) => m.id.equals(memberId))).write(
        MembersCompanion(
          isSuspended: const Value(true),
          status: const Value('paused'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return true;
    });
  }

  Future<bool> atomicResume({
    required int memberId,
    required DateTime resumeDate,
  }) {
    return transaction(() async {
      final sub = await (select(subscriptions)
            ..where((s) => s.memberId.equals(memberId) & s.status.equals('paused'))
            ..orderBy([(s) => OrderingTerm.desc(s.endDate)])
            ..limit(1))
          .getSingleOrNull();

      if (sub == null) return false;

      final pausedDay = AppDateUtils.startOfDay(sub.pausedAt ?? resumeDate);
      final resumeDay = AppDateUtils.startOfDay(resumeDate);
      var shiftDays = resumeDay.difference(pausedDay).inDays;
      if (shiftDays < 0) shiftDays = 0;

      final newEndDate = sub.endDate.add(Duration(days: shiftDays));
      final newTotalPausedDays = sub.totalPausedDays + shiftDays;

      await (update(subscriptions)..where((s) => s.id.equals(sub.id))).write(
        SubscriptionsCompanion(
          status: const Value('active'),
          endDate: Value(newEndDate),
          pausedAt: const Value(null),
          pauseReason: const Value(null),
          totalPausedDays: Value(newTotalPausedDays),
        ),
      );

      await (update(members)..where((m) => m.id.equals(memberId))).write(
        MembersCompanion(
          isSuspended: const Value(false),
          status: const Value('active'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return true;
    });
  }

  Stream<List<Subscription>> watchExpiringSubscriptions({
    required DateTime now,
    int windowDays = 3,
  }) {
    final today = AppDateUtils.startOfDay(now);
    final endWindow = DateTime(now.year, now.month, now.day + windowDays, 23, 59, 59, 999);

    return (select(subscriptions)
          ..where((s) =>
              s.status.equals('active') &
              s.endDate.isBiggerOrEqualValue(today) &
              s.endDate.isSmallerOrEqualValue(endWindow))
          ..orderBy([(s) => OrderingTerm.asc(s.endDate)]))
        .watch();
  }

  Future<int> refreshExpiredStatuses(DateTime now) async {
    final today = AppDateUtils.startOfDay(now);

    return transaction(() async {
      final updatedSubs = await (update(subscriptions)
            ..where((s) =>
                s.status.equals('active') &
                s.endDate.isSmallerThanValue(today)))
          .write(const SubscriptionsCompanion(status: Value('expired')));

      return updatedSubs;
    });
  }

  Future<void> deleteSubscription(int subscriptionId) {
    return transaction(() async {
      final sub = await (select(subscriptions)..where((s) => s.id.equals(subscriptionId))).getSingleOrNull();
      if (sub == null) return;
      final memberId = sub.memberId;

      // Find periods and installments of this subscription
      final periods = await (select(db.subscriptionPeriods)..where((p) => p.subscriptionId.equals(subscriptionId))).get();
      final periodIds = periods.map((p) => p.id).toList();

      List<int> installmentIds = [];
      if (periodIds.isNotEmpty) {
        final insts = await (select(db.installments)..where((i) => i.periodId.isIn(periodIds))).get();
        installmentIds = insts.map((i) => i.id).toList();
      }

      // 1. Delete payments linked to this subscription, its periods, or its installments
      await (delete(payments)..where((p) =>
        p.subscriptionId.equals(subscriptionId) |
        p.periodId.isIn(periodIds) |
        p.installmentId.isIn(installmentIds)
      )).go();

      // 2. Delete installments of periods for this subscription
      if (periodIds.isNotEmpty) {
        await (delete(db.installments)..where((i) => i.periodId.isIn(periodIds))).go();
      }

      // 3. Delete subscription periods
      await (delete(db.subscriptionPeriods)..where((p) => p.subscriptionId.equals(subscriptionId))).go();

      // 4. Delete subscription
      await (delete(subscriptions)..where((s) => s.id.equals(subscriptionId))).go();

      // 5. Check remaining subscriptions for member and update status
      final remainingSubs = await (select(subscriptions)
            ..where((s) => s.memberId.equals(memberId))
            ..orderBy([(s) => OrderingTerm.desc(s.endDate)]))
          .get();

      final now = DateTime.now();
      final today = AppDateUtils.startOfDay(now);

      if (remainingSubs.isNotEmpty) {
        final latestSub = remainingSubs.first;
        final isStillValidDate = !latestSub.endDate.isBefore(today);

        // Reactivate previous subscription if valid date and was marked expired
        if (isStillValidDate && latestSub.status == 'expired') {
          await (update(subscriptions)..where((s) => s.id.equals(latestSub.id))).write(
            const SubscriptionsCompanion(status: Value('active')),
          );
        }

        final memberRow = await (select(members)..where((m) => m.id.equals(memberId))).getSingleOrNull();
        final isSuspended = memberRow?.isSuspended ?? false;

        final newStatus = isSuspended
            ? 'paused'
            : (isStillValidDate ? 'active' : 'expired');

        await (update(members)..where((m) => m.id.equals(memberId))).write(
          MembersCompanion(
            status: Value(newStatus),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await (update(members)..where((m) => m.id.equals(memberId))).write(
          MembersCompanion(
            status: const Value('expired'),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}
