import 'package:equatable/equatable.dart';
import 'finance_enums.dart';

class Payment extends Equatable {
  final int id;
  final int? memberId;
  final String? memberName;
  final int? subscriptionId;
  final int? periodId;
  final int? installmentId;
  final double amount;
  final PaymentMethod? method;
  final DateTime paidAt;
  final String? note;
  final DateTime createdAt;
  final DateTime? voidedAt;
  final String? voidReason;

  const Payment({
    required this.id,
    this.memberId,
    this.memberName,
    this.subscriptionId,
    this.periodId,
    this.installmentId,
    required this.amount,
    this.method,
    required this.paidAt,
    this.note,
    required this.createdAt,
    this.voidedAt,
    this.voidReason,
  });

  bool get isVoided => voidedAt != null;

  @override
  List<Object?> get props => [
        id,
        memberId,
        memberName,
        subscriptionId,
        periodId,
        installmentId,
        amount,
        method,
        paidAt,
        note,
        createdAt,
        voidedAt,
        voidReason,
      ];
}
