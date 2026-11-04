import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/features/security/data/datasources/security_local_datasource.dart';
import 'package:gym_managment_app/features/security/data/repositories/security_repository_impl.dart';
import 'package:gym_managment_app/features/security/presentation/cubit/security_cubit.dart';

void main() {
  late SecurityLocalDataSource localDataSource;
  late SecurityRepositoryImpl repository;
  late SecurityCubit cubit;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    localDataSource = SecurityLocalDataSourceImpl(secureStorage: storage);
    repository = SecurityRepositoryImpl(localDataSource: localDataSource);
    cubit = SecurityCubit(repository: repository);
    await cubit.init();
  });

  test('initial state has isLocked true and default PIN 0000', () async {
    expect(cubit.state.isSecurityEnabled, true);
    expect(cubit.state.isLocked, true);
    expect(cubit.state.hasCustomPin, false);
  });

  test('verifyAndUnlock with correct default PIN 0000 succeeds and unlocks', () async {
    final result = await cubit.verifyAndUnlock('0000');
    expect(result, true);
    expect(cubit.state.isLocked, false);
    expect(cubit.state.errorMessage, isNull);
  });

  test('verifyAndUnlock with incorrect PIN fails and stays locked', () async {
    final result = await cubit.verifyAndUnlock('1234');
    expect(result, false);
    expect(cubit.state.isLocked, true);
    expect(cubit.state.errorMessage, 'رمز المرور غير صحيح');
  });

  test('changePin changes PIN and sets hasCustomPin to true', () async {
    final result = await cubit.changePin(currentPin: '0000', newPin: '5678');
    expect(result, true);
    expect(cubit.state.hasCustomPin, true);
    expect(cubit.state.successMessage, 'تم تغيير رمز المرور بنجاح');

    // Verify old PIN no longer works
    final oldResult = await cubit.verifyOnly('0000');
    expect(oldResult, false);

    // Verify new PIN works
    final newResult = await cubit.verifyOnly('5678');
    expect(newResult, true);
  });

  test('changePin rejects non-4-digit new PIN', () async {
    final result = await cubit.changePin(currentPin: '0000', newPin: '12');
    expect(result, false);
    expect(cubit.state.errorMessage, 'يجب أن يتكون رمز المرور من 4 أرقام');
  });

  test('changePin rejects incorrect current PIN', () async {
    final result = await cubit.changePin(currentPin: '9999', newPin: '1234');
    expect(result, false);
    expect(cubit.state.errorMessage, 'رمز المرور الحالي غير صحيح');
  });

  test('resetPinToDefault restores 0000', () async {
    await cubit.changePin(currentPin: '0000', newPin: '9999');
    expect(cubit.state.hasCustomPin, true);

    await cubit.resetPinToDefault();
    expect(cubit.state.hasCustomPin, false);

    final verifyDefault = await cubit.verifyOnly('0000');
    expect(verifyDefault, true);
  });

  test('toggleSecurityEnabled updates state correctly', () async {
    await cubit.setSecurityEnabled(false);
    expect(cubit.state.isSecurityEnabled, false);
    expect(cubit.state.isLocked, false);

    await cubit.setSecurityEnabled(true);
    expect(cubit.state.isSecurityEnabled, true);
    expect(cubit.state.isLocked, true);
  });
}
