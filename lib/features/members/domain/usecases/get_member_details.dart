import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import '../entities/member.dart';
import '../entities/subscription_history_item.dart';
import '../enums/member_status.dart';
import '../repositories/members_repository.dart';

class MemberDetailsData extends Equatable {
  final Member member;
  final MemberStatusType status;
  final SubscriptionHistoryItem? currentSubscription;
  final List<SubscriptionHistoryItem> subscriptions;
  final List<PaymentHistoryItem> payments;
  final bool hasPayments;

  const MemberDetailsData({
    required this.member,
    required this.status,
    this.currentSubscription,
    required this.subscriptions,
    required this.payments,
    required this.hasPayments,
  });

  @override
  List<Object?> get props => [
        member,
        status,
        currentSubscription,
        subscriptions,
        payments,
        hasPayments,
      ];
}

class GetMemberDetails implements UseCase<MemberDetailsData, int> {
  final MembersRepository repository;

  GetMemberDetails(this.repository);

  @override
  Future<Either<Failure, MemberDetailsData>> call(int memberId) async {
    final memberResult = await repository.getMemberById(memberId);
    return memberResult.fold(
      (failure) => Left(failure),
      (member) async {
        final subsResult = await repository.getMemberSubscriptions(memberId);
        final paymentsResult = await repository.getMemberPayments(memberId);
        final hasPaymentsResult = await repository.hasPayments(memberId);

        final subscriptions = subsResult.getOrElse((_) => []);
        final payments = paymentsResult.getOrElse((_) => []);
        final hasPayments = hasPaymentsResult.getOrElse((_) => false);

        SubscriptionHistoryItem? currentSub;
        if (subscriptions.isNotEmpty) {
          currentSub = subscriptions.first;
        }

        final status = resolveMemberStatus(
          isSuspended: member.isSuspended,
          subscriptionEndDate: currentSub?.endDate,
          now: DateTime.now(),
        );

        return Right(
          MemberDetailsData(
            member: member,
            status: status,
            currentSubscription: currentSub,
            subscriptions: subscriptions,
            payments: payments,
            hasPayments: hasPayments,
          ),
        );
      },
    );
  }
}
