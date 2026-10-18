import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/export_repository.dart';
import 'export_members_csv.dart';

class ExportMembersPdf implements UseCase<File, ExportMembersParams> {
  final ExportRepository _repository;

  ExportMembersPdf(this._repository);

  @override
  Future<Either<Failure, File>> call(ExportMembersParams params) {
    return _repository.exportMembersPdf(
      statusFilter: params.statusFilter,
      includeNotes: params.includeNotes,
    );
  }
}
