import 'package:equatable/equatable.dart';
import '../../domain/entities/backup_info.dart';

enum BackupStatus {
  initial,
  loading,
  inProgress,
  restoreInProgress,
  success,
  restoreSuccess,
  failure,
}

class BackupState extends Equatable {
  final BackupStatus status;
  final BackupInfo? lastBackup;
  final List<BackupInfo> localBackups;
  final BackupInfo? validatedBackup;
  final String? errorMessage;
  final String? successMessage;

  const BackupState({
    this.status = BackupStatus.initial,
    this.lastBackup,
    this.localBackups = const [],
    this.validatedBackup,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading =>
      status == BackupStatus.loading ||
      status == BackupStatus.inProgress ||
      status == BackupStatus.restoreInProgress;

  bool get isStale {
    if (lastBackup == null) return true;
    final diff = DateTime.now().difference(lastBackup!.createdAt).inDays;
    return diff >= 7;
  }

  BackupState copyWith({
    BackupStatus? status,
    BackupInfo? Function()? lastBackup,
    List<BackupInfo>? localBackups,
    BackupInfo? Function()? validatedBackup,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return BackupState(
      status: status ?? this.status,
      lastBackup: lastBackup != null ? lastBackup() : this.lastBackup,
      localBackups: localBackups ?? this.localBackups,
      validatedBackup:
          validatedBackup != null ? validatedBackup() : this.validatedBackup,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage:
          successMessage != null ? successMessage() : this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        lastBackup,
        localBackups,
        validatedBackup,
        errorMessage,
        successMessage,
      ];
}
