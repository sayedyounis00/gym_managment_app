import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';

class SubscriptionHistoryItem extends Equatable {
  final int id;
  final int memberId;
  final String packageName;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final double paidAmount;
  final MemberStatusType status;
  final bool isRenewal;
  final String? paymentMethod;

  const SubscriptionHistoryItem({
    required this.id,
    required this.memberId,
    required this.packageName,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.paidAmount,
    required this.status,
    this.isRenewal = false,
    this.paymentMethod,
  });

  double get remainingAmount => (price - paidAmount).clamp(0, double.infinity);

  PaymentStatusType get paymentStatus {
    if (paidAmount >= price && price > 0) {
      return PaymentStatusType.paid;
    } else if (paidAmount > 0) {
      return PaymentStatusType.partiallyPaid;
    } else {
      return PaymentStatusType.unpaid;
    }
  }

  @override
  List<Object?> get props => [
        id,
        memberId,
        packageName,
        startDate,
        endDate,
        price,
        paidAmount,
        status,
        isRenewal,
        paymentMethod,
      ];
}

class PaymentHistoryItem extends Equatable {
  final int id;
  final int memberId;
  final double amount;
  final DateTime paidAt;
  final String paymentMethod;
  final String? notes;

  const PaymentHistoryItem({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.paidAt,
    required this.paymentMethod,
    this.notes,
  });

  @override
  List<Object?> get props => [id, memberId, amount, paidAt, paymentMethod, notes];
}
