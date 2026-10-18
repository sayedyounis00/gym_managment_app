import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'gender.dart';

class MemberSummary extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String? photoPath;
  final Gender? gender;
  final bool isSuspended;
  final String? packageName;
  final DateTime? subscriptionEndDate;
  final int? daysLeft;
  final MemberStatusType status;

  const MemberSummary({
    required this.id,
    required this.name,
    required this.phone,
    this.photoPath,
    this.gender,
    this.isSuspended = false,
    this.packageName,
    this.subscriptionEndDate,
    this.daysLeft,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        photoPath,
        gender,
        isSuspended,
        packageName,
        subscriptionEndDate,
        daysLeft,
        status,
      ];
}
