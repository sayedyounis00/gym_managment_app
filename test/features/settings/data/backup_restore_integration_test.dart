import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/services/notification_service.dart';
import 'package:gym_managment_app/features/settings/data/datasources/backup_source.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNotificationService extends Mock implements NotificationService {}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockNotificationService mockNotificationService;
  late AppDatabase db;
  late BackupSourceImpl backupSource;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('gym_backup_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    mockNotificationService = MockNotificationService();
    when(() => mockNotificationService.cancelAll()).thenAnswer((_) async {});
    when(() => mockNotificationService.scheduleSubscriptionExpiry(
          subscriptionId: any(named: 'subscriptionId'),
          memberName: any(named: 'memberName'),
          endDate: any(named: 'endDate'),
          daysBefore: any(named: 'daysBefore'),
        )).thenAnswer((_) async {});

    final dbFile = File(p.join(tempDir.path, 'gym_management_app.sqlite'));
    db = AppDatabase(NativeDatabase(dbFile));

    backupSource = BackupSourceImpl(
      db: db,
      secureStorage: const FlutterSecureStorage(),
      notificationService: mockNotificationService,
      onReinitializeDatabase: () async {
        // Ping db to ensure it's reconnected
        final reloadedDb = AppDatabase(NativeDatabase(dbFile));
        await reloadedDb.customSelect('SELECT 1').get();
      },
    );
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Backup and Restore Integration Tests', () {
    test('End-to-End: Create backup, wipe data, restore and verify members, subscriptions and photos match', () async {
      // 1. Insert seed data: Package, Member, Subscription, Payment
      final pkgId = await db.into(db.packages).insert(
            PackagesCompanion.insert(
              name: 'Gold Monthly',
              durationInDays: 30,
              price: 250.0,
            ),
          );

      final memberId = await db.into(db.members).insert(
            MembersCompanion.insert(
              name: 'أحمد علي',
              phone: '01012345678',
              status: const Value('active'),
              gender: const Value('male'),
            ),
          );

      final now = DateTime.now();
      final subId = await db.into(db.subscriptions).insert(
            SubscriptionsCompanion.insert(
              memberId: memberId,
              packageId: Value(pkgId),
              startDate: now,
              endDate: now.add(const Duration(days: 30)),
              isRenewal: const Value(false),
              status: const Value('active'),
            ),
          );

      await db.into(db.payments).insert(
            PaymentsCompanion.insert(
              memberId: memberId,
              subscriptionId: Value(subId),
              amount: 250.0,
              paidAt: Value(now),
            ),
          );

      // Create a dummy photo file in member_photos
      final photosDir = Directory(p.join(tempDir.path, 'member_photos'));
      await photosDir.create(recursive: true);
      final photoFile = File(p.join(photosDir.path, 'member_$memberId.jpg'));
      final photoBytes = utf8.encode('fake_jpeg_image_data_binary');
      await photoFile.writeAsBytes(photoBytes);

      // 2. Perform Backup (share: false for headless test)
      final backupInfo = await backupSource.createBackup(share: false);

      expect(backupInfo.memberCount, 1);
      expect(File(backupInfo.filePath).existsSync(), isTrue);

      // 3. Wipe current database and delete photo
      await db.delete(db.payments).go();
      await db.delete(db.subscriptions).go();
      await db.delete(db.members).go();
      await photoFile.delete();

      final membersAfterWipe = await db.select(db.members).get();
      expect(membersAfterWipe.isEmpty, isTrue);
      expect(photoFile.existsSync(), isFalse);

      // 4. Restore from the backup file
      await backupSource.restoreBackup(backupInfo.filePath);

      // 5. Reconnect to restored database and verify data integrity
      final dbFile = File(p.join(tempDir.path, 'gym_management_app.sqlite'));
      final restoredDb = AppDatabase(NativeDatabase(dbFile));

      final restoredMembers = await restoredDb.select(restoredDb.members).get();
      expect(restoredMembers.length, 1);
      expect(restoredMembers.first.name, 'أحمد علي');
      expect(restoredMembers.first.phone, '01012345678');

      final restoredSubs = await restoredDb.select(restoredDb.subscriptions).get();
      expect(restoredSubs.length, 1);
      expect(restoredSubs.first.memberId, memberId);

      final restoredPayments = await restoredDb.select(restoredDb.payments).get();
      expect(restoredPayments.length, 1);
      expect(restoredPayments.first.amount, 250.0);

      // 6. Verify restored photo
      final restoredPhoto = File(p.join(photosDir.path, 'member_$memberId.jpg'));
      expect(restoredPhoto.existsSync(), isTrue);
      expect(await restoredPhoto.readAsBytes(), photoBytes);

      await restoredDb.close();
    });

    test('Rejects corrupt backup file with descriptive exception', () async {
      final corruptFile = File(p.join(tempDir.path, 'corrupted_backup.gymbak'));
      await corruptFile.writeAsBytes([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

      expect(
        () => backupSource.validateBackupFile(corruptFile.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('Rejects backup created with newer schema version than supported', () async {
      final archive = Archive();
      final dummyDbBytes = utf8.encode('sqlite_mock_bytes');
      final dummyChecksum = sha256.convert(dummyDbBytes).toString();

      final manifestJson = jsonEncode({
        'app_version': '2.0.0',
        'schema_version': 999, // newer than app's current schema
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'member_count': 10,
        'checksum': dummyChecksum,
      });

      archive.addFile(ArchiveFile('manifest.json', manifestJson.length, utf8.encode(manifestJson)));
      archive.addFile(ArchiveFile('database.sqlite', dummyDbBytes.length, dummyDbBytes));

      final zipBytes = ZipEncoder().encode(archive);
      final newSchemaFile = File(p.join(tempDir.path, 'new_schema.gymbak'));
      await newSchemaFile.writeAsBytes(zipBytes);

      expect(
        () => backupSource.validateBackupFile(newSchemaFile.path),
        throwsA(predicate((e) =>
            e is FormatException &&
            e.message.contains('نسخة قاعدة البيانات أحدث من إصدار التطبيق'))),
      );
    });

    test('Rejects backup with tampered database or checksum mismatch', () async {
      final archive = Archive();
      final dummyDbBytes = utf8.encode('original_sqlite_data');
      final tamperedDbBytes = utf8.encode('tampered_sqlite_data');
      final originalChecksum = sha256.convert(dummyDbBytes).toString();

      final manifestJson = jsonEncode({
        'app_version': '1.0.0+1',
        'schema_version': db.schemaVersion,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'member_count': 1,
        'checksum': originalChecksum, // Mismatch with tamperedDbBytes
      });

      archive.addFile(ArchiveFile('manifest.json', manifestJson.length, utf8.encode(manifestJson)));
      archive.addFile(ArchiveFile('database.sqlite', tamperedDbBytes.length, tamperedDbBytes));

      final zipBytes = ZipEncoder().encode(archive);
      final tamperedFile = File(p.join(tempDir.path, 'tampered.gymbak'));
      await tamperedFile.writeAsBytes(zipBytes);

      expect(
        () => backupSource.validateBackupFile(tamperedFile.path),
        throwsA(predicate((e) =>
            e is FormatException &&
            e.message.contains('البصمة الإلكترونية غير متطابقة'))),
      );
    });
  });
}
