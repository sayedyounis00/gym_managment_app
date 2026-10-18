import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../../core/widgets/status_chip.dart';

enum ExportStatus {
  initial,
  exporting,
  success,
  failure,
}

class ExportState extends Equatable {
  final ExportStatus status;
  final MemberStatusType? statusFilter;
  final bool includeNotes;
  final File? exportedFile;
  final String? errorMessage;
  final String? successMessage;

  const ExportState({
    this.status = ExportStatus.initial,
    this.statusFilter,
    this.includeNotes = false,
    this.exportedFile,
    this.errorMessage,
    this.successMessage,
  });

  bool get isExporting => status == ExportStatus.exporting;

  ExportState copyWith({
    ExportStatus? status,
    MemberStatusType? Function()? statusFilter,
    bool? includeNotes,
    File? Function()? exportedFile,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return ExportState(
      status: status ?? this.status,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      includeNotes: includeNotes ?? this.includeNotes,
      exportedFile: exportedFile != null ? exportedFile() : this.exportedFile,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage:
          successMessage != null ? successMessage() : this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        statusFilter,
        includeNotes,
        exportedFile,
        errorMessage,
        successMessage,
      ];
}
