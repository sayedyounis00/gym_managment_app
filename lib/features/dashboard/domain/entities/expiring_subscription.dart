import 'package:equatable/equatable.dart';

class ExpiringSubscription extends Equatable {
  final int memberId;
  final String memberName;
  final String phone;
  final DateTime endDate;
  final int daysLeft;
  final String? packageName;

  const ExpiringSubscription({
    required this.memberId,
    required this.memberName,
    required this.phone,
    required this.endDate,
    required this.daysLeft,
    this.packageName,
  });

  @override
  List<Object?> get props => [
        memberId,
        memberName,
        phone,
        endDate,
        daysLeft,
        packageName,
      ];
}
