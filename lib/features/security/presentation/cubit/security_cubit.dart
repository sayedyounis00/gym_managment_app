import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/security_local_datasource.dart';
import '../../data/repositories/security_repository_impl.dart';
import '../../domain/repositories/security_repository.dart';
import '../../data/services/security_native_service.dart';
import 'security_state.dart';

class SecurityCubit extends Cubit<SecurityState> {
  final SecurityRepository repository;

  SecurityCubit({required this.repository}) : super(const SecurityState());

  Future<void> init() async {
    emit(state.copyWith(isLoading: true));
    try {
      final enabled = await repository.isSecurityEnabled();
      final pin = await repository.getPin();
      final defaultPin = SecurityLocalDataSourceImpl.defaultPin;
      final defaultHash = SecurityRepositoryImpl.hashPin(defaultPin);
      final hasCustom = pin != defaultPin && pin != defaultHash;

      await SecurityNativeService.setSecureMode(enabled);

      emit(state.copyWith(
        isLoading: false,
        isSecurityEnabled: enabled,
        isLocked: enabled, // Enabled means sensitive content starts blurred/locked
        hasCustomPin: hasCustom,
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void unlock() {
    emit(state.copyWith(isLocked: false, clearError: true));
  }

  void lock() {
    if (state.isSecurityEnabled) {
      emit(state.copyWith(isLocked: true));
    }
  }

  Future<bool> verifyAndUnlock(String enteredPin) async {
    final isValid = await repository.verifyPin(enteredPin);
    if (isValid) {
      emit(state.copyWith(isLocked: false, clearError: true));
      return true;
    } else {
      emit(state.copyWith(errorMessage: 'رمز المرور غير صحيح'));
      return false;
    }
  }

  Future<bool> verifyOnly(String enteredPin) async {
    return await repository.verifyPin(enteredPin);
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final isCurrentValid = await repository.verifyPin(currentPin);
    if (!isCurrentValid) {
      emit(state.copyWith(errorMessage: 'رمز المرور الحالي غير صحيح'));
      return false;
    }

    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      emit(state.copyWith(errorMessage: 'يجب أن يتكون رمز المرور من 4 أرقام'));
      return false;
    }

    await repository.setPin(newPin);
    final hasCustom = newPin != SecurityLocalDataSourceImpl.defaultPin;
    emit(state.copyWith(
      hasCustomPin: hasCustom,
      successMessage: 'تم تغيير رمز المرور بنجاح',
      clearError: true,
    ));
    return true;
  }

  Future<void> setSecurityEnabled(bool enabled) async {
    await repository.setSecurityEnabled(enabled);
    await SecurityNativeService.setSecureMode(enabled);
    emit(state.copyWith(
      isSecurityEnabled: enabled,
      isLocked: enabled,
      clearError: true,
    ));
  }

  Future<void> resetPinToDefault() async {
    await repository.resetPinToDefault();
    emit(state.copyWith(
      hasCustomPin: false,
      successMessage: 'تمت استعادة رمز المرور الافتراضي (0000)',
      clearError: true,
    ));
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
