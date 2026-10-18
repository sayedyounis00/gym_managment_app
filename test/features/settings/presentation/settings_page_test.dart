import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/settings/domain/entities/backup_info.dart';
import 'package:gym_managment_app/features/settings/domain/repositories/backup_repository.dart';
import 'package:gym_managment_app/features/settings/domain/repositories/export_repository.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/create_backup.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/export_members_csv.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/export_members_pdf.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/get_last_backup_info.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/restore_backup.dart';
import 'package:gym_managment_app/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:gym_managment_app/features/settings/presentation/cubit/export_cubit.dart';
import 'package:gym_managment_app/features/settings/presentation/pages/export_sheet.dart';
import 'package:gym_managment_app/features/settings/presentation/pages/settings_page.dart';
import 'package:gym_managment_app/features/settings/presentation/widgets/backup_status_card.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupRepository extends Mock implements BackupRepository {}
class MockExportRepository extends Mock implements ExportRepository {}
class MockCreateBackup extends Mock implements CreateBackup {}
class MockRestoreBackup extends Mock implements RestoreBackup {}
class MockGetLastBackupInfo extends Mock implements GetLastBackupInfo {}
class MockExportMembersCsv extends Mock implements ExportMembersCsv {}
class MockExportMembersPdf extends Mock implements ExportMembersPdf {}

void main() {
  final sl = GetIt.instance;
  late MockBackupRepository mockBackupRepo;
  late MockCreateBackup mockCreateBackup;
  late MockRestoreBackup mockRestoreBackup;
  late MockGetLastBackupInfo mockGetLastBackupInfo;
  late MockExportMembersCsv mockExportCsv;
  late MockExportMembersPdf mockExportPdf;

  setUpAll(() async {
    await initializeDateFormatting('ar', null);
    registerFallbackValue(const NoParams());
  });

  setUp(() async {
    await sl.reset();

    mockBackupRepo = MockBackupRepository();
    mockCreateBackup = MockCreateBackup();
    mockRestoreBackup = MockRestoreBackup();
    mockGetLastBackupInfo = MockGetLastBackupInfo();
    mockExportCsv = MockExportMembersCsv();
    mockExportPdf = MockExportMembersPdf();

    when(() => mockBackupRepo.getLocalBackups())
        .thenAnswer((_) async => const Right([]));
    when(() => mockGetLastBackupInfo(any()))
        .thenAnswer((_) async => const Right(null));

    sl.registerFactory<BackupCubit>(
      () => BackupCubit(
        createBackupUseCase: mockCreateBackup,
        restoreBackupUseCase: mockRestoreBackup,
        getLastBackupInfoUseCase: mockGetLastBackupInfo,
        backupRepository: mockBackupRepo,
      ),
    );

    sl.registerFactory<ExportCubit>(
      () => ExportCubit(
        exportMembersCsv: mockExportCsv,
        exportMembersPdf: mockExportPdf,
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    );
  }

  group('Settings UI & Widget Tests', () {
    testWidgets('SettingsPage renders all three section groups and tiles', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('البيانات'), findsOneWidget);
      expect(find.text('التنبيهات'), findsOneWidget);
      expect(find.text('عن التطبيق'), findsOneWidget);

      expect(find.text('النسخ الاحتياطي والاستعادة'), findsOneWidget);
      expect(find.text('نسخ احتياطي الآن'), findsOneWidget);
      expect(find.text('تصدير المشتركين'), findsOneWidget);
      expect(find.text('تفعيل التنبيهات'), findsOneWidget);
      expect(find.text('إصدار التطبيق'), findsOneWidget);
    });

    testWidgets('BackupStatusCard shows protected state when backup is fresh', (tester) async {
      final freshBackup = BackupInfo(
        filePath: '/tmp/fresh.gymbak',
        fileName: 'fresh.gymbak',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        memberCount: 20,
        appVersion: '1.0.0+1',
        schemaVersion: 6,
        databaseChecksum: 'fresh_checksum',
        fileSizeBytes: 2048,
      );

      await tester.pumpWidget(
        buildTestableWidget(BackupStatusCard(lastBackup: freshBackup)),
      );
      await tester.pumpAndSettle();

      expect(find.text('البيانات محمية بنسخة احتياطية'), findsOneWidget);
      expect(find.textContaining('المشتركين: 20'), findsOneWidget);
    });

    testWidgets('BackupStatusCard shows warning state when backup is stale (> 7 days)', (tester) async {
      final staleBackup = BackupInfo(
        filePath: '/tmp/stale.gymbak',
        fileName: 'stale.gymbak',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        memberCount: 12,
        appVersion: '1.0.0+1',
        schemaVersion: 6,
        databaseChecksum: 'stale_checksum',
        fileSizeBytes: 1024,
      );

      await tester.pumpWidget(
        buildTestableWidget(BackupStatusCard(lastBackup: staleBackup)),
      );
      await tester.pumpAndSettle();

      expect(find.text('النسخة الاحتياطية قديمة'), findsOneWidget);
    });

    testWidgets('ExportSheet renders filter chips and export buttons', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: BlocProvider(
              create: (_) => sl<ExportCubit>()..setStatusFilter(MemberStatusType.active),
              child: const ExportSheet(initialStatusFilter: MemberStatusType.active),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تصدير بيانات المشتركين'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      expect(find.text('ينتهي قريباً'), findsOneWidget);
      expect(find.text('منتهي'), findsOneWidget);
      expect(find.text('موقوف'), findsOneWidget);

      expect(find.text('تضمين الملاحظات'), findsOneWidget);
      expect(find.text('تصدير كملف Excel (CSV)'), findsOneWidget);
      expect(find.text('تصدير كملف PDF'), findsOneWidget);
    });
  });
}
