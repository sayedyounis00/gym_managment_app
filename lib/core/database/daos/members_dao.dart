import 'package:drift/drift.dart';
import '../../utils/arabic_search_utils.dart';
import '../../utils/date_utils.dart';
import '../../widgets/status_chip.dart';
import '../../../features/members/domain/enums/member_status.dart';
import '../app_database.dart';
import '../tables/member_notes_table.dart';
import '../tables/members_table.dart';
import '../tables/packages_table.dart';
import '../tables/payments_table.dart';
import '../tables/subscriptions_table.dart';

part 'members_dao.g.dart';

class MemberWithSubscriptionData {
  final Member member;
  final Subscription? subscription;
  final Package? package;
  final MemberStatusType status;
  final int? daysLeft;

  MemberWithSubscriptionData({
    required this.member,
    this.subscription,
    this.package,
    required this.status,
    this.daysLeft,
  });
}

@DriftAccessor(tables: [
  Members,
  Packages,
  Subscriptions,
  Payments,
  MemberNotes,
])
class MembersDao extends DatabaseAccessor<AppDatabase> with _$MembersDaoMixin {
  MembersDao(super.db);

  Stream<List<MemberWithSubscriptionData>> watchMembersWithStatus({
    String? query,
    MemberStatusType? statusFilter,
    int daysBeforeExpiry = 7,
  }) {
    // Select all members
    final membersQuery = select(members)
      ..orderBy([(m) => OrderingTerm.asc(m.name)]);

    return membersQuery.watch().asyncMap((allMembers) async {
      final now = DateTime.now();
      final today = AppDateUtils.startOfDay(now);

      final result = <MemberWithSubscriptionData>[];

      // Normalized search query
      final cleanQuery = (query != null && query.trim().isNotEmpty)
          ? ArabicSearchUtils.normalize(query)
          : null;
      final cleanPhoneQuery = (query != null && query.trim().isNotEmpty)
          ? ArabicSearchUtils.normalizePhone(query)
          : null;

      for (final m in allMembers) {
        // Search filter matching
        if (cleanQuery != null) {
          final normName = m.searchName ?? ArabicSearchUtils.normalize(m.name);
          final normPhone = ArabicSearchUtils.normalizePhone(m.phone);
          final matchesName = normName.contains(cleanQuery);
          final matchesPhone = cleanPhoneQuery != null &&
              cleanPhoneQuery.isNotEmpty &&
              normPhone.contains(cleanPhoneQuery);

          if (!matchesName && !matchesPhone) {
            continue;
          }
        }

        // Fetch latest subscription for this member
        final subQuery = (select(subscriptions)
              ..where((s) => s.memberId.equals(m.id))
              ..orderBy([(s) => OrderingTerm.desc(s.endDate)])
              ..limit(1))
            .join([
          leftOuterJoin(packages, packages.id.equalsExp(subscriptions.packageId)),
        ]);

        final subRows = await subQuery.get();
        Subscription? latestSub;
        Package? latestPackage;

        if (subRows.isNotEmpty) {
          latestSub = subRows.first.readTable(subscriptions);
          latestPackage = subRows.first.readTableOrNull(packages);
        }

        // Resolve status
        final status = resolveMemberStatus(
          isSuspended: m.isSuspended,
          subscriptionEndDate: latestSub?.endDate,
          daysBeforeExpiry: daysBeforeExpiry,
          now: now,
        );

        // Apply status filter if set
        if (statusFilter != null && status != statusFilter) {
          continue;
        }

        int? daysLeft;
        if (latestSub != null) {
          final end = AppDateUtils.startOfDay(latestSub.endDate);
          daysLeft = end.difference(today).inDays;
        }

        result.add(
          MemberWithSubscriptionData(
            member: m,
            subscription: latestSub,
            package: latestPackage,
            status: status,
            daysLeft: daysLeft,
          ),
        );
      }

      return result;
    });
  }

  Future<Member?> getMemberById(int id) {
    return (select(members)..where((m) => m.id.equals(id))).getSingleOrNull();
  }

  Stream<Member> watchMemberById(int id) {
    return (select(members)..where((m) => m.id.equals(id))).watchSingle();
  }

  Future<int> insertMember(MembersCompanion companion) {
    return into(members).insert(companion);
  }

  Future<bool> updateMember(MembersCompanion companion) {
    return update(members).replace(companion);
  }

  Future<int> toggleSuspension(int id, bool isSuspended) {
    return (update(members)..where((m) => m.id.equals(id))).write(
      MembersCompanion(
        isSuspended: Value(isSuspended),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> hasPayments(int memberId) async {
    final countExp = payments.id.count();
    final query = selectOnly(payments)
      ..addColumns([countExp])
      ..where(payments.memberId.equals(memberId));
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return (result ?? 0) > 0;
  }

  Future<void> deleteMember(int id) async {
    // Defensively ensure any legacy attendance table is dropped
    await customStatement('DROP TABLE IF EXISTS attendance;');

    return transaction(() async {
      final memberSubs = await (select(subscriptions)..where((s) => s.memberId.equals(id))).get();
      final subIds = memberSubs.map((s) => s.id).toList();

      List<int> periodIds = [];
      List<int> installmentIds = [];

      if (subIds.isNotEmpty) {
        final periods = await (select(db.subscriptionPeriods)..where((p) => p.subscriptionId.isIn(subIds))).get();
        periodIds = periods.map((p) => p.id).toList();

        if (periodIds.isNotEmpty) {
          final insts = await (select(db.installments)..where((i) => i.periodId.isIn(periodIds))).get();
          installmentIds = insts.map((i) => i.id).toList();
        }
      }

      // 1. Delete payments first (payments reference member, subscriptions, periods, and installments)
      Expression<bool> paymentsPredicate = payments.memberId.equals(id);
      if (subIds.isNotEmpty) {
        paymentsPredicate = paymentsPredicate | payments.subscriptionId.isIn(subIds);
      }
      if (periodIds.isNotEmpty) {
        paymentsPredicate = paymentsPredicate | payments.periodId.isIn(periodIds);
      }
      if (installmentIds.isNotEmpty) {
        paymentsPredicate = paymentsPredicate | payments.installmentId.isIn(installmentIds);
      }
      await (delete(payments)..where((p) => paymentsPredicate)).go();

      // 2. Delete installments (installments reference subscriptionPeriods)
      if (periodIds.isNotEmpty) {
        await (delete(db.installments)..where((i) => i.periodId.isIn(periodIds))).go();
      }

      // 3. Delete subscription periods (subscriptionPeriods reference subscriptions)
      if (subIds.isNotEmpty) {
        await (delete(db.subscriptionPeriods)..where((p) => p.subscriptionId.isIn(subIds))).go();
      }

      // 4. Delete subscriptions (subscriptions reference members)
      await (delete(subscriptions)..where((s) => s.memberId.equals(id))).go();

      // 5. Delete member notes
      await (delete(memberNotes)..where((n) => n.memberId.equals(id))).go();

      // 6. Delete member
      await (delete(members)..where((m) => m.id.equals(id))).go();
    });
  }

  Future<List<TypedResult>> getMemberSubscriptionsWithPackages(int memberId) {
    return (select(subscriptions)..where((s) => s.memberId.equals(memberId)))
        .join([
          leftOuterJoin(packages, packages.id.equalsExp(subscriptions.packageId)),
        ])
        .get();
  }

  Future<List<Payment>> getMemberPayments(int memberId) {
    return (select(payments)
          ..where((p) => p.memberId.equals(memberId))
          ..orderBy([(p) => OrderingTerm.desc(p.paidAt)]))
        .get();
  }

  Future<int> recordMemberPayment({
    required int memberId,
    required double amount,
    required String paymentMethod,
    required DateTime paidAt,
    int? subscriptionId,
    String? notes,
  }) {
    return transaction(() async {
      final paymentId = await into(payments).insert(
        PaymentsCompanion.insert(
          memberId: memberId,
          amount: amount,
          paymentMethod: Value(paymentMethod),
          paidAt: Value(paidAt),
          subscriptionId: Value(subscriptionId),
          notes: Value(notes),
        ),
      );

      if (subscriptionId != null) {
        final sub = await (select(subscriptions)
              ..where((s) => s.id.equals(subscriptionId)))
            .getSingleOrNull();
        if (sub != null) {
          final newPaid = sub.amountPaid + amount;
          await (update(subscriptions)
                ..where((s) => s.id.equals(subscriptionId)))
              .write(
            SubscriptionsCompanion(amountPaid: Value(newPaid)),
          );
        }
      }

      return paymentId;
    });
  }
}
