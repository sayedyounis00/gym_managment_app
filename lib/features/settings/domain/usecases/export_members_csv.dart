import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/widgets/status_chip.dart';
import '../repositories/export_repository.dart';

class ExportMembersParams extends Equatable {
  final MemberStatusType? statusFilter;
  final bool includeNotes;

  const ExportMembersParams({
    this.statusFilter,
    this.includeNotes = false,
  });

  @override
  List<Object?> get props => [statusFilter, includeNotes];
}

class ExportMembersCsv implements UseCase<File, ExportMembersParams> {
  final ExportRepository repository;

  ExportMembersCsv(this.repository);

  @override
  Future<Either<Failure, File>> call(ExportMembersParams params) {
    return repository.exportMembersCsv(
      statusFilter: params.statusFilter,
      includeNotes: params.includeNotes,
    );
  }
}
