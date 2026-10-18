import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/backup_info.dart';
import '../repositories/backup_repository.dart';

class CreateBackupParams extends Equatable {
  final bool share;

  const CreateBackupParams({this.share = true});

  @override
  List<Object?> get props => [share];
}

class CreateBackup implements UseCase<BackupInfo, CreateBackupParams> {
  final BackupRepository _repository;

  CreateBackup(this._repository);

  @override
  Future<Either<Failure, BackupInfo>> call(CreateBackupParams params) {
    return _repository.createBackup(share: params.share);
  }
}
