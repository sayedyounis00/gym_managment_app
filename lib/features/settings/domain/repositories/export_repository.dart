import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/status_chip.dart';

abstract class ExportRepository {
  Future<Either<Failure, File>> exportMembersCsv({
    MemberStatusType? statusFilter,
    bool includeNotes = false,
  });

  Future<Either<Failure, File>> exportMembersPdf({
    MemberStatusType? statusFilter,
    bool includeNotes = false,
  });
}
