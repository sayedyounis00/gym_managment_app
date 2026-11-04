import 'package:equatable/equatable.dart';

class SecurityState extends Equatable {
  final bool isLocked;
  final bool isSecurityEnabled;
  final bool hasCustomPin;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const SecurityState({
    this.isLocked = true,
    this.isSecurityEnabled = true,
    this.hasCustomPin = false,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  SecurityState copyWith({
    bool? isLocked,
    bool? isSecurityEnabled,
    bool? hasCustomPin,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SecurityState(
      isLocked: isLocked ?? this.isLocked,
      isSecurityEnabled: isSecurityEnabled ?? this.isSecurityEnabled,
      hasCustomPin: hasCustomPin ?? this.hasCustomPin,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLocked,
        isSecurityEnabled,
        hasCustomPin,
        isLoading,
        errorMessage,
        successMessage,
      ];
}
