import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import 'package:gym_managment_app/features/settings/domain/entities/backup_info.dart';
import 'package:gym_managment_app/features/settings/domain/repositories/backup_repository.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/create_backup.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/get_last_backup_info.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/restore_backup.dart';
import 'package:gym_managment_app/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:gym_managment_app/features/settings/presentation/cubit/backup_state.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateBackup extends Mock implements CreateBackup {}
class MockRestoreBackup extends Mock implements RestoreBackup {}
class MockGetLastBackupInfo extends Mock implements GetLastBackupInfo {}
class MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  late MockCreateBackup mockCreateBackup;
  late MockRestoreBackup mockRestoreBackup;
  late MockGetLastBackupInfo mockGetLastBackupInfo;
  late MockBackupRepository mockBackupRepository;
  late BackupCubit backupCubit;

  final testBackup = BackupInfo(
    filePath: '/app/backups/test.gymbak',
    fileName: 'test.gymbak',
    createdAt: DateTime(2026, 10, 18, 12, 0),
    memberCount: 5,
    appVersion: '1.0.0+1',
    schemaVersion: 6,
    databaseChecksum: 'checksum123',
    fileSizeBytes: 1024,
  );

  setUp(() {
    mockCreateBackup = MockCreateBackup();
    mockRestoreBackup = MockRestoreBackup();
    mockGetLastBackupInfo = MockGetLastBackupInfo();
    mockBackupRepository = MockBackupRepository();

    registerFallbackValue(const CreateBackupParams());
    registerFallbackValue(const RestoreBackupParams(filePath: ''));
    registerFallbackValue(const NoParams());

    backupCubit = BackupCubit(
      createBackupUseCase: mockCreateBackup,
      restoreBackupUseCase: mockRestoreBackup,
      getLastBackupInfoUseCase: mockGetLastBackupInfo,
      backupRepository: mockBackupRepository,
    );
  });

  tearDown(() {
    backupCubit.close();
  });

  group('BackupCubit Tests', () {
    test('initial state has default values', () {
      expect(backupCubit.state.status, equals(BackupStatus.initial));
      expect(backupCubit.state.lastBackup, isNull);
      expect(backupCubit.state.localBackups, isEmpty);
      expect(backupCubit.state.isLoading, isFalse);
    });

    blocTest<BackupCubit, BackupState>(
      'init loads last backup and local backups',
      build: () {
        when(() => mockGetLastBackupInfo(any()))
            .thenAnswer((_) async => Right(testBackup));
        when(() => mockBackupRepository.getLocalBackups())
            .thenAnswer((_) async => Right([testBackup]));
        return backupCubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const BackupState(status: BackupStatus.loading),
        BackupState(
          status: BackupStatus.initial,
          lastBackup: testBackup,
          localBackups: [testBackup],
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      'createBackup emits [inProgress, success] on success',
      build: () {
        when(() => mockCreateBackup(any()))
            .thenAnswer((_) async => Right(testBackup));
        when(() => mockBackupRepository.getLocalBackups())
            .thenAnswer((_) async => Right([testBackup]));
        return backupCubit;
      },
      act: (cubit) => cubit.createBackup(),
      expect: () => [
        const BackupState(status: BackupStatus.inProgress),
        BackupState(
          status: BackupStatus.success,
          lastBackup: testBackup,
          localBackups: [testBackup],
          successMessage: 'تم إنشاء النسخة الاحتياطية بنجاح.',
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      'createBackup emits [inProgress, failure] on failure',
      build: () {
        when(() => mockCreateBackup(any()))
            .thenAnswer((_) async => const Left(DatabaseFailure('فشل الكتابة')));
        return backupCubit;
      },
      act: (cubit) => cubit.createBackup(),
      expect: () => [
        const BackupState(status: BackupStatus.inProgress),
        const BackupState(
          status: BackupStatus.failure,
          errorMessage: 'فشل الكتابة',
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      'restoreBackup emits [restoreInProgress, loading, initial, restoreSuccess] on success',
      build: () {
        when(() => mockRestoreBackup(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetLastBackupInfo(any()))
            .thenAnswer((_) async => Right(testBackup));
        when(() => mockBackupRepository.getLocalBackups())
            .thenAnswer((_) async => Right([testBackup]));
        return backupCubit;
      },
      act: (cubit) => cubit.restoreBackup('/path/to/backup.gymbak'),
      expect: () => [
        const BackupState(status: BackupStatus.restoreInProgress),
        const BackupState(status: BackupStatus.loading),
        BackupState(
          status: BackupStatus.initial,
          lastBackup: testBackup,
          localBackups: [testBackup],
        ),
        BackupState(
          status: BackupStatus.restoreSuccess,
          lastBackup: testBackup,
          localBackups: [testBackup],
          successMessage: 'تمت استعادة البيانات بنجاح.',
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      'restoreBackup emits [restoreInProgress, failure] on failure',
      build: () {
        when(() => mockRestoreBackup(any()))
            .thenAnswer((_) async => const Left(DatabaseFailure('الملف تالف')));
        return backupCubit;
      },
      act: (cubit) => cubit.restoreBackup('/path/to/corrupt.gymbak'),
      expect: () => [
        const BackupState(status: BackupStatus.restoreInProgress),
        const BackupState(
          status: BackupStatus.failure,
          errorMessage: 'الملف تالف',
        ),
      ],
    );
  });
}
