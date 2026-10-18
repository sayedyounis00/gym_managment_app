import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/backup_info.dart';
import '../repositories/backup_repository.dart';

class GetLastBackupInfo implements UseCase<BackupInfo?, NoParams> {
  final BackupRepository _repository;

  GetLastBackupInfo(this._repository);

  @override
  Future<Either<Failure, BackupInfo?>> call(NoParams params) {
    return _repository.getLastBackupInfo();
  }
}
