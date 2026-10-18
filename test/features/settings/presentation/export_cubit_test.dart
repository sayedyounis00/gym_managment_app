import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/export_members_csv.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/export_members_pdf.dart';
import 'package:gym_managment_app/features/settings/presentation/cubit/export_cubit.dart';
import 'package:gym_managment_app/features/settings/presentation/cubit/export_state.dart';
import 'package:mocktail/mocktail.dart';

class MockExportMembersCsv extends Mock implements ExportMembersCsv {}
class MockExportMembersPdf extends Mock implements ExportMembersPdf {}

void main() {
  late MockExportMembersCsv mockExportCsv;
  late MockExportMembersPdf mockExportPdf;
  late ExportCubit exportCubit;

  setUp(() {
    mockExportCsv = MockExportMembersCsv();
    mockExportPdf = MockExportMembersPdf();

    registerFallbackValue(const ExportMembersParams());

    exportCubit = ExportCubit(
      exportMembersCsv: mockExportCsv,
      exportMembersPdf: mockExportPdf,
    );
  });

  tearDown(() {
    exportCubit.close();
  });

  group('ExportCubit Tests', () {
    test('initial state has default filter and notes disabled', () {
      expect(exportCubit.state.status, equals(ExportStatus.initial));
      expect(exportCubit.state.statusFilter, isNull);
      expect(exportCubit.state.includeNotes, isFalse);
    });

    test('setStatusFilter updates filter state', () {
      exportCubit.setStatusFilter(MemberStatusType.active);
      expect(exportCubit.state.statusFilter, equals(MemberStatusType.active));

      exportCubit.setStatusFilter(null);
      expect(exportCubit.state.statusFilter, isNull);
    });

    test('toggleIncludeNotes updates notes boolean', () {
      exportCubit.toggleIncludeNotes(true);
      expect(exportCubit.state.includeNotes, isTrue);

      exportCubit.toggleIncludeNotes(false);
      expect(exportCubit.state.includeNotes, isFalse);
    });

    blocTest<ExportCubit, ExportState>(
      'exportCsv emits [exporting, success] on success',
      build: () {
        when(() => mockExportCsv(any()))
            .thenAnswer((_) async => Right(File('/tmp/test.csv')));
        return exportCubit;
      },
      act: (cubit) => cubit.exportCsv(),
      expect: () => [
        const ExportState(status: ExportStatus.exporting),
        isA<ExportState>()
            .having((s) => s.status, 'status', ExportStatus.success)
            .having((s) => s.successMessage, 'message', contains('CSV')),
      ],
    );

    blocTest<ExportCubit, ExportState>(
      'exportPdf emits [exporting, success] on success',
      build: () {
        when(() => mockExportPdf(any()))
            .thenAnswer((_) async => Right(File('/tmp/test.pdf')));
        return exportCubit;
      },
      act: (cubit) => cubit.exportPdf(),
      expect: () => [
        const ExportState(status: ExportStatus.exporting),
        isA<ExportState>()
            .having((s) => s.status, 'status', ExportStatus.success)
            .having((s) => s.successMessage, 'message', contains('PDF')),
      ],
    );

    blocTest<ExportCubit, ExportState>(
      'exportCsv emits [exporting, failure] on failure',
      build: () {
        when(() => mockExportCsv(any()))
            .thenAnswer((_) async => const Left(DatabaseFailure('فشل تصدير CSV')));
        return exportCubit;
      },
      act: (cubit) => cubit.exportCsv(),
      expect: () => [
        const ExportState(status: ExportStatus.exporting),
        const ExportState(
          status: ExportStatus.failure,
          errorMessage: 'فشل تصدير CSV',
        ),
      ],
    );
  });
}
