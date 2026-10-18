import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/backup_info.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/backup_source.dart';

class BackupRepositoryImpl implements BackupRepository {
  final BackupSource backupSource;

  BackupRepositoryImpl({required this.backupSource});

  @override
  Future<Either<Failure, BackupInfo>> createBackup({bool share = true}) async {
    try {
      final info = await backupSource.createBackup(share: share);
      return Right(info);
    } catch (e) {
      return Left(DatabaseFailure('فشل إنشاء النسخة الاحتياطية: $e'));
    }
  }

  @override
  Future<Either<Failure, BackupInfo>> validateBackupFile(String filePath) async {
    try {
      final info = await backupSource.validateBackupFile(filePath);
      return Right(info);
    } catch (e) {
      return Left(DatabaseFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> restoreBackup(String filePath) async {
    try {
      await backupSource.restoreBackup(filePath);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, BackupInfo?>> getLastBackupInfo() async {
    try {
      final info = await backupSource.getLastBackupInfo();
      return Right(info);
    } catch (e) {
      return Left(DatabaseFailure('فشل جلب بيانات آخر نسخة احتياطية: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BackupInfo>>> getLocalBackups() async {
    try {
      final list = await backupSource.getLocalBackups();
      return Right(list);
    } catch (e) {
      return Left(DatabaseFailure('فشل جلب النسخ الاحتياطية المحلية: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> shareBackup(String filePath) async {
    try {
      await backupSource.shareBackup(filePath);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل مشاركة النسخة الاحتياطية: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBackup(String filePath) async {
    try {
      await backupSource.deleteBackup(filePath);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل حذف النسخة الاحتياطية: $e'));
    }
  }
}
