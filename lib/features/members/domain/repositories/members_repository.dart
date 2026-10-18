import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import '../entities/gender.dart';
import '../entities/member.dart';
import '../entities/member_summary.dart';
import '../entities/subscription_history_item.dart';

abstract class MembersRepository {
  Stream<List<MemberSummary>> watchMembers({
    String? query,
    MemberStatusType? statusFilter,
  });

  Future<Either<Failure, Member>> getMemberById(int id);

  Stream<Member> watchMemberById(int id);

  Future<Either<Failure, int>> addMember({
    required String name,
    required String phone,
    String? photoPath,
    Gender? gender,
    int? age,
    double? weightKg,
    double? heightCm,
    String? initialNote,
  });

  Future<Either<Failure, Unit>> updateMember(Member member);

  Future<Either<Failure, Unit>> toggleMemberSuspension(int id, bool isSuspended);

  Future<Either<Failure, Unit>> deleteMember(int id);

  Future<Either<Failure, bool>> hasPayments(int memberId);

  Future<Either<Failure, List<SubscriptionHistoryItem>>> getMemberSubscriptions(int memberId);

  Future<Either<Failure, List<PaymentHistoryItem>>> getMemberPayments(int memberId);

  Future<Either<Failure, Unit>> recordPayment({
    required int memberId,
    required double amount,
    required String paymentMethod,
    required DateTime paidAt,
    int? subscriptionId,
    String? notes,
  });
}
