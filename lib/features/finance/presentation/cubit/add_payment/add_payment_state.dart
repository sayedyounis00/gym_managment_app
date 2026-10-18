import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/features/finance/domain/entities/finance_enums.dart';

class MemberPeriodOption extends Equatable {
  final int? subscriptionId;
  final int? periodId;
  final String label;
  final double dueAmount;
  final double paidAmount;
  final double remaining;
  final DateTime startDate;

  const MemberPeriodOption({
    this.subscriptionId,
    this.periodId,
    required this.label,
    required this.dueAmount,
    required this.paidAmount,
    required this.remaining,
    required this.startDate,
  });

  @override
  List<Object?> get props => [
        subscriptionId,
        periodId,
        label,
        dueAmount,
        paidAmount,
        remaining,
        startDate,
      ];
}

class AddPaymentState extends Equatable {
  final bool isLoading;
  final List<Member> allMembers;
  final int? selectedMemberId;
  final String? selectedMemberName;
  final List<MemberPeriodOption> periodOptions;
  final MemberPeriodOption? selectedPeriod;
  final double amount;
  final PaymentMethod? method;
  final DateTime paidAt;
  final String? note;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  const AddPaymentState({
    this.isLoading = false,
    this.allMembers = const [],
    this.selectedMemberId,
    this.selectedMemberName,
    this.periodOptions = const [],
    this.selectedPeriod,
    this.amount = 0.0,
    this.method = PaymentMethod.cash,
    required this.paidAt,
    this.note,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  double get periodRemaining => selectedPeriod?.remaining ?? 0.0;

  double get remainingAfterPayment {
    final rem = periodRemaining - amount;
    return rem < 0 ? 0.0 : rem;
  }

  PaymentStatus get postPaymentStatus {
    if (selectedPeriod == null) return PaymentStatus.paid;
    final totalPaidAfter = (selectedPeriod!.paidAmount + amount);
    return PaymentStatus.fromAmounts(totalPaidAfter, selectedPeriod!.dueAmount);
  }

  AddPaymentState copyWith({
    bool? isLoading,
    List<Member>? allMembers,
    int? selectedMemberId,
    String? selectedMemberName,
    List<MemberPeriodOption>? periodOptions,
    MemberPeriodOption? selectedPeriod,
    bool clearSelectedPeriod = false,
    double? amount,
    PaymentMethod? method,
    bool clearMethod = false,
    DateTime? paidAt,
    String? note,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddPaymentState(
      isLoading: isLoading ?? this.isLoading,
      allMembers: allMembers ?? this.allMembers,
      selectedMemberId: selectedMemberId ?? this.selectedMemberId,
      selectedMemberName: selectedMemberName ?? this.selectedMemberName,
      periodOptions: periodOptions ?? this.periodOptions,
      selectedPeriod: clearSelectedPeriod ? null : (selectedPeriod ?? this.selectedPeriod),
      amount: amount ?? this.amount,
      method: clearMethod ? null : (method ?? this.method),
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        allMembers,
        selectedMemberId,
        selectedMemberName,
        periodOptions,
        selectedPeriod,
        amount,
        method,
        paidAt,
        note,
        isSubmitting,
        isSuccess,
        errorMessage,
      ];
}
