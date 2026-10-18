import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/backup_repository.dart';

class RestoreBackupParams extends Equatable {
  final String filePath;

  const RestoreBackupParams({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class RestoreBackup implements UseCase<void, RestoreBackupParams> {
  final BackupRepository _repository;

  RestoreBackup(this._repository);

  @override
  Future<Either<Failure, void>> call(RestoreBackupParams params) {
    return _repository.restoreBackup(params.filePath);
  }
}
