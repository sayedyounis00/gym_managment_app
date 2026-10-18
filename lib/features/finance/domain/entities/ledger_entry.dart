import 'package:equatable/equatable.dart';
import 'finance_enums.dart';

class LedgerEntry extends Equatable {
  final String id;
  final int originalId;
  final LedgerType type;
  final double amount;
  final DateTime date;
  final String title;
  final String? subtitle;
  final PaymentMethod? method;
  final int? memberId;
  final String? memberPhone;
  final String? memberAvatarUrl;
  final ExpenseCategory? category;
  final bool isVoided;
  final String? voidReason;

  const LedgerEntry({
    required this.id,
    required this.originalId,
    required this.type,
    required this.amount,
    required this.date,
    required this.title,
    this.subtitle,
    this.method,
    this.memberId,
    this.memberPhone,
    this.memberAvatarUrl,
    this.category,
    required this.isVoided,
    this.voidReason,
  });

  @override
  List<Object?> get props => [
        id,
        originalId,
        type,
        amount,
        date,
        title,
        subtitle,
        method,
        memberId,
        memberPhone,
        memberAvatarUrl,
        category,
        isVoided,
        voidReason,
      ];
}
