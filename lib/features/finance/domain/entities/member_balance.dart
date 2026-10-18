import 'package:equatable/equatable.dart';

class MemberBalance extends Equatable {
  final int memberId;
  final String memberName;
  final String memberPhone;
  final String? memberAvatarUrl;
  final double totalDue;
  final double totalPaid;
  final double remaining;
  final DateTime? lastPaymentDate;
  final int? activeSubscriptionId;
  final String? activePackageName;

  const MemberBalance({
    required this.memberId,
    required this.memberName,
    required this.memberPhone,
    this.memberAvatarUrl,
    required this.totalDue,
    required this.totalPaid,
    required this.remaining,
    this.lastPaymentDate,
    this.activeSubscriptionId,
    this.activePackageName,
  });

  @override
  List<Object?> get props => [
        memberId,
        memberName,
        memberPhone,
        memberAvatarUrl,
        totalDue,
        totalPaid,
        remaining,
        lastPaymentDate,
        activeSubscriptionId,
        activePackageName,
      ];
}
