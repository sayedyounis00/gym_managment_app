import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/backup_info.dart';

abstract class BackupRepository {
  Future<Either<Failure, BackupInfo>> createBackup({bool share = true});
  Future<Either<Failure, BackupInfo>> validateBackupFile(String filePath);
  Future<Either<Failure, void>> restoreBackup(String filePath);
  Future<Either<Failure, BackupInfo?>> getLastBackupInfo();
  Future<Either<Failure, List<BackupInfo>>> getLocalBackups();
  Future<Either<Failure, void>> shareBackup(String filePath);
  Future<Either<Failure, void>> deleteBackup(String filePath);
}
