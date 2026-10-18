import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/repositories/export_repository.dart';
import '../datasources/export_source.dart';

class ExportRepositoryImpl implements ExportRepository {
  final ExportSource exportSource;

  ExportRepositoryImpl({required this.exportSource});

  @override
  Future<Either<Failure, File>> exportMembersCsv({
    MemberStatusType? statusFilter,
    bool includeNotes = false,
  }) async {
    try {
      final file = await exportSource.exportMembersCsv(
        statusFilter: statusFilter,
        includeNotes: includeNotes,
      );
      return Right(file);
    } catch (e) {
      return Left(DatabaseFailure('فشل تصدير البيانات إلى CSV: $e'));
    }
  }

  @override
  Future<Either<Failure, File>> exportMembersPdf({
    MemberStatusType? statusFilter,
    bool includeNotes = false,
  }) async {
    try {
      final file = await exportSource.exportMembersPdf(
        statusFilter: statusFilter,
        includeNotes: includeNotes,
      );
      return Right(file);
    } catch (e) {
      return Left(DatabaseFailure('فشل تصدير البيانات إلى PDF: $e'));
    }
  }
}
