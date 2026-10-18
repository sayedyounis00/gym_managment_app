import 'package:equatable/equatable.dart';
import '../../../domain/entities/membership_package.dart';

class RenewState extends Equatable {
  final int memberId;
  final String memberName;
  final List<MembershipPackage> activePackages;
  final MembershipPackage? selectedPackage;
  final DateTime startDate;
  final DateTime endDate;
  final double amountPaid;
  final String paymentMethod; // 'cash' | 'transfer' | 'wallet'
  final int? previousSubscriptionId;
  final bool isLoading;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final int? newSubscriptionId;

  const RenewState({
    this.memberId = 0,
    this.memberName = '',
    this.activePackages = const [],
    this.selectedPackage,
    required this.startDate,
    required this.endDate,
    this.amountPaid = 0.0,
    this.paymentMethod = 'cash',
    this.previousSubscriptionId,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.newSubscriptionId,
  });

  double get packagePrice => selectedPackage?.price ?? 0.0;
  double get remainingAmount => (packagePrice - amountPaid).clamp(0.0, double.infinity);

  RenewState copyWith({
    int? memberId,
    String? memberName,
    List<MembershipPackage>? activePackages,
    MembershipPackage? selectedPackage,
    DateTime? startDate,
    DateTime? endDate,
    double? amountPaid,
    String? paymentMethod,
    int? previousSubscriptionId,
    bool? isLoading,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? newSubscriptionId,
  }) {
    return RenewState(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      activePackages: activePackages ?? this.activePackages,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      previousSubscriptionId: previousSubscriptionId ?? this.previousSubscriptionId,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      newSubscriptionId: newSubscriptionId ?? this.newSubscriptionId,
    );
  }

  @override
  List<Object?> get props => [
        memberId,
        memberName,
        activePackages,
        selectedPackage,
        startDate,
        endDate,
        amountPaid,
        paymentMethod,
        previousSubscriptionId,
        isLoading,
        isSubmitting,
        isSuccess,
        errorMessage,
        newSubscriptionId,
      ];
}
