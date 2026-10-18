import 'package:equatable/equatable.dart';

class PauseState extends Equatable {
  final int memberId;
  final DateTime pauseDate;
  final String? reason;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? actionType; // 'pause' | 'resume'

  const PauseState({
    this.memberId = 0,
    required this.pauseDate,
    this.reason,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.actionType,
  });

  PauseState copyWith({
    int? memberId,
    DateTime? pauseDate,
    String? reason,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionType,
  }) {
    return PauseState(
      memberId: memberId ?? this.memberId,
      pauseDate: pauseDate ?? this.pauseDate,
      reason: reason ?? this.reason,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionType: actionType ?? this.actionType,
    );
  }

  @override
  List<Object?> get props => [
        memberId,
        pauseDate,
        reason,
        isSubmitting,
        isSuccess,
        errorMessage,
        actionType,
      ];
}
