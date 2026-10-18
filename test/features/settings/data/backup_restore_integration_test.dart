// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/services/notification_service.dart';
import 'package:gym_managment_app/features/settings/data/datasources/backup_source.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final sl = GetIt.instance;
  late Directory tempDir;
  late MockNotificationService mockNotificationService;
  late AppDatabase db;
  late BackupSourceImpl backupSource;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await sl.reset();
    tempDir = await Directory.systemTemp.createTemp('gym_backup_test_');

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
    sl.registerSingleton<AppDatabase>(db);
    await db.customSelect('SELECT 1').get();

    backupSource = BackupSourceImpl(
      db: db,
      secureStorage: const FlutterSecureStorage(),
      notificationService: mockNotificationService,
      getDocumentsDirectory: () async => tempDir,
      onReinitializeDatabase: () async {
        if (sl.isRegistered<AppDatabase>()) {
          await sl.unregister<AppDatabase>();
        }
        final reloadedDb = AppDatabase(NativeDatabase(dbFile));
        sl.registerSingleton<AppDatabase>(reloadedDb);
        await reloadedDb.customSelect('SELECT 1').get();
      },
    );
  });

  tearDown(() async {
    if (sl.isRegistered<AppDatabase>()) {
      try {
        await sl<AppDatabase>().close();
      } catch (_) {}
    } else {
      try {
        await db.close();
      } catch (_) {}
    }
    await sl.reset();
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

    test('Restores successfully when user selects extracted database.sqlite from unzipped folder', () async {
      // Create extracted folder structure like in user's image
      final extractedDir = Directory(p.join(tempDir.path, 'extracted_folder'));
      await extractedDir.create(recursive: true);

      // Create a dummy sqlite db with header
      final extractedDbFile = File(p.join(extractedDir.path, 'database.sqlite'));
      final realDbFile = File(p.join(tempDir.path, 'gym_management_app.sqlite'));
      await realDbFile.copy(extractedDbFile.path);

      final extractedDbBytes = await extractedDbFile.readAsBytes();
      final checksum = sha256.convert(extractedDbBytes).toString();

      final manifestFile = File(p.join(extractedDir.path, 'manifest.json'));
      await manifestFile.writeAsString(jsonEncode({
        'app_version': '1.0.0+1',
        'schema_version': db.schemaVersion,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'member_count': 5,
        'checksum': checksum,
      }));

      // Validate selecting database.sqlite directly
      final validated = await backupSource.validateBackupFile(extractedDbFile.path);
      expect(validated.memberCount, 5);
      expect(validated.databaseChecksum, checksum);

      // Restore selecting database.sqlite directly
      await backupSource.restoreBackup(extractedDbFile.path);
      expect(realDbFile.existsSync(), isTrue);
    });

    test('Restores successfully when user selects extracted manifest.json from unzipped folder', () async {
      final extractedDir = Directory(p.join(tempDir.path, 'extracted_manifest_folder'));
      await extractedDir.create(recursive: true);

      final extractedDbFile = File(p.join(extractedDir.path, 'database.sqlite'));
      final realDbFile = File(p.join(tempDir.path, 'gym_management_app.sqlite'));
      await realDbFile.copy(extractedDbFile.path);

      final checksum = sha256.convert(await extractedDbFile.readAsBytes()).toString();
      final manifestFile = File(p.join(extractedDir.path, 'manifest.json'));
      await manifestFile.writeAsString(jsonEncode({
        'app_version': '1.0.0+1',
        'schema_version': db.schemaVersion,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'member_count': 8,
        'checksum': checksum,
      }));

      final validated = await backupSource.validateBackupFile(manifestFile.path);
      expect(validated.memberCount, 8);

      await backupSource.restoreBackup(manifestFile.path);
      expect(realDbFile.existsSync(), isTrue);
    });

    test('Restores successfully when zip archive wraps files in a subfolder', () async {
      final realDbFile = File(p.join(tempDir.path, 'gym_management_app.sqlite'));
      final dbBytes = await realDbFile.readAsBytes();
      final checksum = sha256.convert(dbBytes).toString();

      final manifestJson = jsonEncode({
        'app_version': '1.0.0+1',
        'schema_version': db.schemaVersion,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'member_count': 12,
        'checksum': checksum,
      });

      final archive = Archive();
      // Add files with a folder prefix, e.g. "gym_backup_20261018/manifest.json"
      archive.addFile(ArchiveFile('gym_backup_20261018/manifest.json', manifestJson.length, utf8.encode(manifestJson)));
      archive.addFile(ArchiveFile('gym_backup_20261018/database.sqlite', dbBytes.length, dbBytes));

      final zipBytes = ZipEncoder().encode(archive);
      final nestedZipFile = File(p.join(tempDir.path, 'nested_folder_backup.gymbak'));
      await nestedZipFile.writeAsBytes(zipBytes);

      final validated = await backupSource.validateBackupFile(nestedZipFile.path);
      expect(validated.memberCount, 12);

      await backupSource.restoreBackup(nestedZipFile.path);
      expect(realDbFile.existsSync(), isTrue);
    });
  });
}
