import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/members_dao.dart';
import 'package:gym_managment_app/core/database/daos/notes_dao.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/services/image_storage_service.dart';
import 'package:gym_managment_app/core/utils/arabic_search_utils.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
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
        return MemberSummary(
          id: item.member.id,
          name: item.member.name,
          phone: item.member.phone,
          photoPath: item.member.photoPath,
          isSuspended: item.member.isSuspended,
          packageName: item.package?.name,
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
      final hasPay = await membersDao.hasPayments(id);
      if (hasPay) {
        return const Left(
          DatabaseFailure(
            'لا يمكن حذف المشترك لوجود سجلات مالية مسجلة له. يمكنك إيقافه مؤقتاً.',
          ),
        );
      }

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

      final list = rows.map((r) {
        final sub = r.readTable(membersDao.subscriptions);
        final pkg = r.readTableOrNull(membersDao.packages);

        final relatedPayments = allPayments.where((p) => p.subscriptionId == sub.id);
        final totalPaid = relatedPayments.fold<double>(
          0.0,
          (sum, p) => sum + p.amount,
        );

        final price = pkg?.price ?? 0.0;
        final status = resolveMemberStatus(
          isSuspended: sub.status == 'paused',
          subscriptionEndDate: sub.endDate,
          now: now,
        );

        final paymentMethod = relatedPayments.isNotEmpty
            ? relatedPayments.first.paymentMethod
            : (sub.amountPaid > 0 ? 'cash' : null);

        return SubscriptionHistoryItem(
          id: sub.id,
          memberId: sub.memberId,
          packageName: pkg?.name ?? 'باقة مخصصة',
          startDate: sub.startDate,
          endDate: sub.endDate,
          price: price,
          paidAmount: totalPaid,
          status: status,
          isRenewal: sub.isRenewal,
          paymentMethod: paymentMethod,
        );
      }).toList();

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
        );
      }).toList();
      return Right(list);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  domain.Member _mapToDomainMember(Member row) {
    return domain.Member(
      id: row.id,
      name: row.name,
      phone: row.phone,
      photoPath: row.photoPath,
      age: row.age,
      weightKg: row.weightKg,
      heightCm: row.heightCm,
      isSuspended: row.isSuspended,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
