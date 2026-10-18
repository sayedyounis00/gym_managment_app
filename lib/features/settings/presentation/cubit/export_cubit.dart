import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/usecases/export_members_csv.dart';
import '../../domain/usecases/export_members_pdf.dart';
import 'export_state.dart';

class ExportCubit extends Cubit<ExportState> {
  final ExportMembersCsv exportMembersCsv;
  final ExportMembersPdf exportMembersPdf;

  ExportCubit({
    required this.exportMembersCsv,
    required this.exportMembersPdf,
    MemberStatusType? initialStatusFilter,
  }) : super(ExportState(statusFilter: initialStatusFilter));

  void setStatusFilter(MemberStatusType? filter) {
    emit(state.copyWith(statusFilter: () => filter));
  }

  void toggleIncludeNotes(bool value) {
    emit(state.copyWith(includeNotes: value));
  }

  Future<void> exportCsv() async {
    emit(state.copyWith(
      status: ExportStatus.exporting,
      errorMessage: () => null,
      successMessage: () => null,
    ));

    final result = await exportMembersCsv(
      ExportMembersParams(
        statusFilter: state.statusFilter,
        includeNotes: state.includeNotes,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ExportStatus.failure,
        errorMessage: () => failure.message,
      )),
      (file) => emit(state.copyWith(
        status: ExportStatus.success,
        exportedFile: () => file,
        successMessage: () => 'تم تصدير ملف CSV ومشاركته بنجاح.',
      )),
    );
  }

  Future<void> exportPdf() async {
    emit(state.copyWith(
      status: ExportStatus.exporting,
      errorMessage: () => null,
      successMessage: () => null,
    ));

    final result = await exportMembersPdf(
      ExportMembersParams(
        statusFilter: state.statusFilter,
        includeNotes: state.includeNotes,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ExportStatus.failure,
        errorMessage: () => failure.message,
      )),
      (file) => emit(state.copyWith(
        status: ExportStatus.success,
        exportedFile: () => file,
        successMessage: () => 'تم تصدير ملف PDF ومشاركته بنجاح.',
      )),
    );
  }

  void reset() {
    emit(state.copyWith(
      status: ExportStatus.initial,
      errorMessage: () => null,
      successMessage: () => null,
      exportedFile: () => null,
    ));
  }
}
