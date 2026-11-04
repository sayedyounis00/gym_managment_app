import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/members_dao.dart';
import 'package:gym_managment_app/core/database/daos/notes_dao.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/services/image_storage_service.dart';
import 'package:gym_managment_app/core/utils/arabic_search_utils.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/gender.dart' as domain;
import 'package:gym_managment_app/features/members/domain/entities/member.dart' as domain;
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';
import 'package:gym_managment_app/features/members/domain/entities/subscription_history_item.dart';
import 'package:gym_managment_app/features/members/domain/enums/member_status.dart';
import 'package:gym_managment_app/features/members/domain/repositories/members_repository.dart';

class MembersRepositoryImpl implements MembersRepository {
  final MembersDao membersDao;
  final NotesDao notesDao;
  final ImageStorageService imageStorageService;

  MembersRepositoryImpl({
    required this.membersDao,
    required this.notesDao,
    required this.imageStorageService,
  });

  @override
  Stream<List<MemberSummary>> watchMembers({
    String? query,
    MemberStatusType? statusFilter,
  }) {
    return membersDao
        .watchMembersWithStatus(
      query: query,
      statusFilter: statusFilter,
    )
        .map((list) {
      return list.map((item) {
        final domain.Gender? gender = item.member.gender != null
            ? (item.member.gender == 'female'
                ? domain.Gender.female
                : domain.Gender.male)
            : null;
        return MemberSummary(
          id: item.member.id,
          name: item.member.name,
          phone: item.member.phone,
          photoPath: item.member.photoPath,
          gender: gender,
          isSuspended: item.member.isSuspended,
          packageName: item.subscription?.packageNameSnapshot ?? item.package?.name,
          subscriptionEndDate: item.subscription?.endDate,
          daysLeft: item.daysLeft,
          status: item.status,
        );
      }).toList();
    });
  }

  @override
  Future<Either<Failure, domain.Member>> getMemberById(int id) async {
    try {
      final row = await membersDao.getMemberById(id);
      if (row == null) {
        return const Left(DatabaseFailure('المشترك غير موجود'));
      }
      return Right(_mapToDomainMember(row));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<domain.Member> watchMemberById(int id) {
    return membersDao.watchMemberById(id).map(_mapToDomainMember);
  }

  @override
  Future<Either<Failure, int>> addMember({
    required String name,
    required String phone,
    String? photoPath,
    domain.Gender? gender,
    int? age,
    double? weightKg,
    double? heightCm,
    String? initialNote,
  }) async {
    try {
      final normalizedPhone = ArabicSearchUtils.normalizePhone(phone);
      final searchName = ArabicSearchUtils.normalize(name);
      final now = DateTime.now();

      final companion = MembersCompanion.insert(
        name: name.trim(),
        phone: normalizedPhone,
        photoPath: Value(photoPath),
        gender: Value(gender?.name),
        age: Value(age),
        weightKg: Value(weightKg),
        heightCm: Value(heightCm),
        isSuspended: const Value(false),
        status: const Value('active'),
        searchName: Value(searchName),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      final memberId = await membersDao.insertMember(companion);

      if (initialNote != null && initialNote.trim().isNotEmpty) {
        await notesDao.insertNote(memberId, initialNote.trim());
      }

      return Right(memberId);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique') || msg.contains('phone')) {
        return const Left(DatabaseFailure('رقم الهاتف مسجل لمشترك آخر بالفعل'));
      }
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMember(domain.Member member) async {
    try {
      final normalizedPhone = ArabicSearchUtils.normalizePhone(member.phone);
      final searchName = ArabicSearchUtils.normalize(member.name);

      final companion = MembersCompanion(
        id: Value(member.id),
        name: Value(member.name.trim()),
        phone: Value(normalizedPhone),
        photoPath: Value(member.photoPath),
        gender: Value(member.gender?.name),
        age: Value(member.age),
        weightKg: Value(member.weightKg),
        heightCm: Value(member.heightCm),
        isSuspended: Value(member.isSuspended),
        status: Value(member.isSuspended ? 'paused' : 'active'),
        searchName: Value(searchName),
        updatedAt: Value(DateTime.now()),
      );

      await membersDao.updateMember(companion);
      return const Right(unit);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique') || msg.contains('phone')) {
        return const Left(DatabaseFailure('رقم الهاتف مسجل لمشترك آخر بالفعل'));
      }
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleMemberSuspension(int id, bool isSuspended) async {
    try {
      await membersDao.toggleSuspension(id, isSuspended);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMember(int id) async {
    try {
      final member = await membersDao.getMemberById(id);
      if (member?.photoPath != null) {
        await imageStorageService.deletePhoto(member!.photoPath!);
      }

      await membersDao.deleteMember(id);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasPayments(int memberId) async {
    try {
      final result = await membersDao.hasPayments(memberId);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionHistoryItem>>> getMemberSubscriptions(
    int memberId,
  ) async {
    try {
      final rows = await membersDao.getMemberSubscriptionsWithPackages(memberId);
      final allPayments = await membersDao.getMemberPayments(memberId);
      final now = DateTime.now();

      final list = <SubscriptionHistoryItem>[];
      for (final r in rows) {
        final sub = r.readTable(membersDao.subscriptions);
        final pkg = r.readTableOrNull(membersDao.packages);

        final relatedPayments = allPayments.where((p) => p.subscriptionId == sub.id);
        final totalPaidFromPayments = relatedPayments.fold<double>(
          0.0,
          (sum, p) => sum + p.amount,
        );
        final totalPaid = totalPaidFromPayments > 0 ? totalPaidFromPayments : sub.amountPaid;

        final isPayAsYouGo = sub.isPayAsYouGo || (pkg?.isPayAsYouGo ?? false);
        final dailyRate = sub.priceSnapshot ?? pkg?.price ?? 0.0;
        int attendedCount = 0;
        if (isPayAsYouGo) {
          final countExpr = membersDao.db.attendanceLogs.id.count();
          final q = membersDao.selectOnly(membersDao.db.attendanceLogs)
            ..addColumns([countExpr])
            ..where(membersDao.db.attendanceLogs.subscriptionId.equals(sub.id));
          attendedCount = (await q.map((row) => row.read(countExpr)).getSingle()) ?? 0;
        }

        final price = isPayAsYouGo ? (attendedCount * dailyRate) : (sub.priceSnapshot ?? pkg?.price ?? 0.0);
        final status = (sub.status == 'expired')
            ? MemberStatusType.expired
            : resolveMemberStatus(
                isSuspended: sub.status == 'paused',
                subscriptionEndDate: sub.endDate,
                now: now,
              );

        final paymentMethod = relatedPayments.isNotEmpty
            ? relatedPayments.first.paymentMethod
            : (sub.amountPaid > 0 ? 'cash' : null);

        final isDaily = isPayAsYouGo ||
            (pkg != null && pkg.durationValue == 1 && pkg.durationUnit == 'days') ||
            (pkg?.trackAttendance == true);

        list.add(SubscriptionHistoryItem(
          id: sub.id,
          memberId: sub.memberId,
          packageName: sub.packageNameSnapshot ?? pkg?.name ?? 'باقة مخصصة',
          startDate: sub.startDate,
          endDate: sub.endDate,
          price: price,
          paidAmount: totalPaid,
          status: status,
          isRenewal: sub.isRenewal,
          trackAttendance: sub.trackAttendance || (pkg?.trackAttendance ?? false),
          paymentMethod: paymentMethod,
          isDaily: isDaily,
          isPayAsYouGo: isPayAsYouGo,
          attendedDaysCount: attendedCount,
          dailyRate: dailyRate,
        ));
      }

      list.sort((a, b) => b.endDate.compareTo(a.endDate));
      return Right(list);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentHistoryItem>>> getMemberPayments(
    int memberId,
  ) async {
    try {
      final payments = await membersDao.getMemberPayments(memberId);
      final list = payments.map((p) {
        return PaymentHistoryItem(
          id: p.id,
          memberId: p.memberId,
          amount: p.amount,
          paidAt: p.paidAt,
          paymentMethod: p.paymentMethod,
          notes: p.notes,
          voidedAt: p.voidedAt,
          voidReason: p.voidReason,
        );
      }).toList();
      return Right(list);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> recordPayment({
    required int memberId,
    required double amount,
    required String paymentMethod,
    required DateTime paidAt,
    int? subscriptionId,
    String? notes,
  }) async {
    try {
      await membersDao.recordMemberPayment(
        memberId: memberId,
        amount: amount,
        paymentMethod: paymentMethod,
        paidAt: paidAt,
        subscriptionId: subscriptionId,
        notes: notes,
      );
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  domain.Member _mapToDomainMember(Member row) {
    final domain.Gender? gender = row.gender != null
        ? (row.gender == 'female'
            ? domain.Gender.female
            : domain.Gender.male)
        : null;

    return domain.Member(
      id: row.id,
      name: row.name,
      phone: row.phone,
      photoPath: row.photoPath,
      gender: gender,
      age: row.age,
      weightKg: row.weightKg,
      heightCm: row.heightCm,
      isSuspended: row.isSuspended,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
