import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import 'package:gym_managment_app/features/settings/domain/entities/backup_info.dart';
import 'package:gym_managment_app/features/settings/domain/repositories/backup_repository.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/create_backup.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/get_last_backup_info.dart';
import 'package:gym_managment_app/features/settings/domain/usecases/restore_backup.dart';
import 'package:gym_managment_app/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:gym_managment_app/features/settings/presentation/pages/backup_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupRepository extends Mock implements BackupRepository {}
class MockCreateBackup extends Mock implements CreateBackup {}
class MockRestoreBackup extends Mock implements RestoreBackup {}
class MockGetLastBackupInfo extends Mock implements GetLastBackupInfo {}

void main() {
  final sl = GetIt.instance;
  late MockBackupRepository mockBackupRepo;
  late MockCreateBackup mockCreateBackup;
  late MockRestoreBackup mockRestoreBackup;
  late MockGetLastBackupInfo mockGetLastBackupInfo;

  setUpAll(() async {
    await initializeDateFormatting('ar', null);
    registerFallbackValue(const NoParams());
    registerFallbackValue(const CreateBackupParams(share: false));
    registerFallbackValue(const RestoreBackupParams(filePath: ''));
  });

  setUp(() async {
    await sl.reset();

    mockBackupRepo = MockBackupRepository();
    mockCreateBackup = MockCreateBackup();
    mockRestoreBackup = MockRestoreBackup();
    mockGetLastBackupInfo = MockGetLastBackupInfo();

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

  group('BackupPage Widget Tests', () {
    testWidgets('renders action buttons and empty local backups message', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BackupPage()));
      await tester.pumpAndSettle();

      expect(find.text('النسخ الاحتياطي والاستعادة'), findsOneWidget);
      expect(find.text('نسخ احتياطي الآن'), findsOneWidget);
      expect(find.text('استعادة من نسخة'), findsOneWidget);
    });

    testWidgets('renders local backups when available', (tester) async {
      final sampleBackup = BackupInfo(
        filePath: '/data/backups/gym_backup_20261018.gymbak',
        fileName: 'gym_backup_20261018.gymbak',
        createdAt: DateTime(2026, 10, 18, 14, 30),
        memberCount: 45,
        appVersion: '1.0.0+1',
        schemaVersion: 6,
        databaseChecksum: 'sample_checksum',
        fileSizeBytes: 1024 * 50,
      );

      when(() => mockBackupRepo.getLocalBackups())
          .thenAnswer((_) async => Right([sampleBackup]));
      when(() => mockGetLastBackupInfo(any()))
          .thenAnswer((_) async => Right(sampleBackup));

      await tester.pumpWidget(buildTestableWidget(const BackupPage()));
      await tester.pumpAndSettle();

      expect(find.text('البيانات محمية بنسخة احتياطية'), findsOneWidget);
      expect(find.text('gym_backup_20261018.gymbak'), findsOneWidget);
      expect(find.textContaining('45 مشترك'), findsOneWidget);
    });

    testWidgets('tapping backup button invokes createBackup', (tester) async {
      final newBackup = BackupInfo(
        filePath: '/data/backups/new.gymbak',
        fileName: 'new.gymbak',
        createdAt: DateTime.now(),
        memberCount: 5,
        appVersion: '1.0.0+1',
        schemaVersion: 6,
        databaseChecksum: 'hash',
        fileSizeBytes: 2048,
      );

      when(() => mockCreateBackup(any()))
          .thenAnswer((_) async => Right(newBackup));

      await tester.pumpWidget(buildTestableWidget(const BackupPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('نسخ احتياطي الآن'));
      await tester.pump();

      verify(() => mockCreateBackup(any())).called(1);
    });
  });
}
