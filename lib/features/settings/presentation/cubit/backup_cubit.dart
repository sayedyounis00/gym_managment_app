import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/backup_info.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/usecases/create_backup.dart';
import '../../domain/usecases/get_last_backup_info.dart';
import '../../domain/usecases/restore_backup.dart';
import 'backup_state.dart';

class BackupCubit extends Cubit<BackupState> {
  final CreateBackup createBackupUseCase;
  final RestoreBackup restoreBackupUseCase;
  final GetLastBackupInfo getLastBackupInfoUseCase;
  final BackupRepository backupRepository;

  BackupCubit({
    required this.createBackupUseCase,
    required this.restoreBackupUseCase,
    required this.getLastBackupInfoUseCase,
    required this.backupRepository,
  }) : super(const BackupState());

  Future<void> init() async {
    emit(state.copyWith(status: BackupStatus.loading));
    final lastResult = await getLastBackupInfoUseCase(const NoParams());
    final localResult = await backupRepository.getLocalBackups();

    BackupInfo? lastBackup;
    lastResult.fold(
      (failure) => null,
      (info) => lastBackup = info,
    );

    List<BackupInfo> localBackups = [];
    localResult.fold(
      (failure) => null,
      (list) => localBackups = list,
    );

    emit(state.copyWith(
      status: BackupStatus.initial,
      lastBackup: () => lastBackup,
      localBackups: localBackups,
      errorMessage: () => null,
    ));
  }

  Future<void> createBackup({bool share = true}) async {
    emit(state.copyWith(status: BackupStatus.inProgress, errorMessage: () => null));

    final result = await createBackupUseCase(CreateBackupParams(share: share));
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: BackupStatus.failure,
          errorMessage: () => failure.message,
        ));
      },
      (backupInfo) async {
        final localResult = await backupRepository.getLocalBackups();
        final localList = localResult.getOrElse((_) => [backupInfo]);

        emit(state.copyWith(
          status: BackupStatus.success,
          lastBackup: () => backupInfo,
          localBackups: localList,
          successMessage: () => 'تم إنشاء النسخة الاحتياطية بنجاح.',
        ));
      },
    );
  }

  Future<BackupInfo?> validateBackup(String filePath) async {
    final result = await backupRepository.validateBackupFile(filePath);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: BackupStatus.failure,
          errorMessage: () => failure.message,
        ));
        return null;
      },
      (info) {
        emit(state.copyWith(validatedBackup: () => info));
        return info;
      },
    );
  }

  Future<void> restoreBackup(String filePath) async {
    emit(state.copyWith(
      status: BackupStatus.restoreInProgress,
      errorMessage: () => null,
    ));

    final result = await restoreBackupUseCase(RestoreBackupParams(filePath: filePath));
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: BackupStatus.failure,
          errorMessage: () => failure.message,
        ));
      },
      (_) async {
        await init();
        emit(state.copyWith(
          status: BackupStatus.restoreSuccess,
          successMessage: () => 'تمت استعادة البيانات بنجاح.',
        ));
      },
    );
  }

  Future<void> shareBackup(String filePath) async {
    await backupRepository.shareBackup(filePath);
  }

  Future<void> deleteBackup(String filePath) async {
    final result = await backupRepository.deleteBackup(filePath);
    result.fold(
      (failure) => emit(state.copyWith(
        status: BackupStatus.failure,
        errorMessage: () => failure.message,
      )),
      (_) async => await init(),
    );
  }

  void resetStatus() {
    emit(state.copyWith(
      status: BackupStatus.initial,
      errorMessage: () => null,
      successMessage: () => null,
    ));
  }
}
