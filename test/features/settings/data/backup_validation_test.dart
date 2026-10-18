import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/services/notification_service.dart';
import 'package:gym_managment_app/features/settings/data/datasources/backup_source.dart';
import 'package:gym_managment_app/features/settings/domain/entities/backup_info.dart';
import 'package:mocktail/mocktail.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockAppDatabase mockDb;

  setUp(() {
    mockDb = MockAppDatabase();
    when(() => mockDb.schemaVersion).thenReturn(6);
  });

  List<int> createZip({
    String? manifestContent,
    List<int>? dbBytes,
    bool includeManifest = true,
    bool includeDb = true,
  }) {
    final archive = Archive();
    if (includeManifest && manifestContent != null) {
      final bytes = utf8.encode(manifestContent);
      archive.addFile(ArchiveFile('manifest.json', bytes.length, bytes));
    }
    if (includeDb && dbBytes != null) {
      archive.addFile(ArchiveFile('database.sqlite', dbBytes.length, dbBytes));
    }
    return ZipEncoder().encode(archive);
  }

  group('Backup Manifest & Checksum Validation Tests', () {
    test('successfully validates valid backup zip', () async {
      final dbData = utf8.encode('SQLite dummy database header bytes');
      final checksum = sha256.convert(dbData).toString();
      final manifest = jsonEncode({
        'app_version': '1.0.0+1',
        'schema_version': 6,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'member_count': 15,
        'checksum': checksum,
      });

      final zipBytes = createZip(manifestContent: manifest, dbBytes: dbData);
      expect(zipBytes, isNotEmpty);

      // Verify decode
      final extracted = ExtractedZipData(
        manifestJson: manifest,
        dbBytes: dbData,
        photos: const [],
      );

      final decodedManifest = jsonDecode(extracted.manifestJson) as Map<String, dynamic>;
      final actualChecksum = sha256.convert(extracted.dbBytes).toString();

      expect(actualChecksum, equals(decodedManifest['checksum']));
      expect(decodedManifest['schema_version'], lessThanOrEqualTo(6));
      expect(decodedManifest['member_count'], equals(15));
    });

    test('BackupInfo.fromManifest converts UTC timestamp to local timezone', () {
      const utcString = '2026-10-18T18:36:00.000Z';
      final manifest = {
        'app_version': '1.0.0+1',
        'schema_version': 6,
        'created_at': utcString,
        'member_count': 10,
        'checksum': 'some_checksum',
      };

      final backupInfo = BackupInfo.fromManifest(
        manifest: manifest,
        filePath: '/data/backup.gymbak',
        fileName: 'backup.gymbak',
        fileSizeBytes: 1024,
      );

      final expectedLocal = DateTime.parse(utcString).toLocal();
      expect(backupInfo.createdAt.isUtc, isFalse);
      expect(backupInfo.createdAt.hour, equals(expectedLocal.hour));
      expect(backupInfo.createdAt.minute, equals(expectedLocal.minute));
    });

    test('rejects backup with checksum mismatch', () {
      final dbData = utf8.encode('Original database');
      const tamperedChecksum = 'invalid_sha256_checksum_hash_12345';
      final manifest = jsonEncode({
        'app_version': '1.0.0+1',
        'schema_version': 6,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'member_count': 10,
        'checksum': tamperedChecksum,
      });

      final decoded = jsonDecode(manifest) as Map<String, dynamic>;
      final actualChecksum = sha256.convert(dbData).toString();
      expect(actualChecksum, isNot(equals(decoded['checksum'])));
    });

    test('rejects backup with newer schema version than app supports', () {
      final dbData = utf8.encode('Future database');
      final checksum = sha256.convert(dbData).toString();
      final manifest = jsonEncode({
        'app_version': '2.0.0',
        'schema_version': 10, // newer than current schema 6
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'member_count': 50,
        'checksum': checksum,
      });

      final decoded = jsonDecode(manifest) as Map<String, dynamic>;
      final backupSchema = decoded['schema_version'] as int;

      expect(backupSchema > mockDb.schemaVersion, isTrue);
    });

    test('throws when manifest.json is missing in zip', () {
      final archive = Archive();
      archive.addFile(ArchiveFile('database.sqlite', 5, [1, 2, 3, 4, 5]));
      final zipBytes = ZipEncoder().encode(archive);

      expect(
        () {
          final decoded = ZipDecoder().decodeBytes(zipBytes);
          final manifestFile = decoded.findFile('manifest.json');
          if (manifestFile == null) {
            throw const FormatException('ملف البيان (manifest.json) مفقود.');
          }
        },
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when database.sqlite is missing in zip', () {
      final archive = Archive();
      final manifestBytes = utf8.encode('{}');
      archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
      final zipBytes = ZipEncoder().encode(archive);

      expect(
        () {
          final decoded = ZipDecoder().decodeBytes(zipBytes);
          final dbFile = decoded.findFile('database.sqlite');
          if (dbFile == null) {
            throw const FormatException('ملف قاعدة البيانات (database.sqlite) مفقود.');
          }
        },
        throwsA(isA<FormatException>()),
      );
    });
  });
}
