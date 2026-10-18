import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/backup_info.dart';

class BackupZipEntry {
  final String path;
  final List<int> bytes;

  const BackupZipEntry(this.path, this.bytes);
}

class ExtractedZipData {
  final String manifestJson;
  final List<int> dbBytes;
  final List<BackupZipEntry> photos;

  const ExtractedZipData({
    required this.manifestJson,
    required this.dbBytes,
    required this.photos,
  });
}

List<int> _encodeZipIsolate(List<BackupZipEntry> entries) {
  final archive = Archive();
  for (final entry in entries) {
    archive.addFile(ArchiveFile(entry.path, entry.bytes.length, entry.bytes));
  }
  return ZipEncoder().encode(archive);
}

ExtractedZipData _decodeZipIsolate(List<int> zipBytes) {
  final archive = ZipDecoder().decodeBytes(zipBytes);
  String? manifestJson;
  List<int>? dbBytes;
  final photos = <BackupZipEntry>[];

  for (final file in archive) {
    if (!file.isFile) continue;
    if (file.name == 'manifest.json') {
      manifestJson = utf8.decode(file.content as List<int>);
    } else if (file.name == 'database.sqlite') {
      dbBytes = file.content as List<int>;
    } else if (file.name.startsWith('photos/')) {
      photos.add(BackupZipEntry(file.name, file.content as List<int>));
    }
  }

  if (manifestJson == null) {
    throw const FormatException('ملف النسخة الاحتياطية غير صالح: ملف البيان (manifest.json) مفقود.');
  }
  if (dbBytes == null) {
    throw const FormatException('ملف النسخة الاحتياطية غير صالح: ملف قاعدة البيانات (database.sqlite) مفقود.');
  }

  return ExtractedZipData(
    manifestJson: manifestJson,
    dbBytes: dbBytes,
    photos: photos,
  );
}

abstract class BackupSource {
  Future<BackupInfo> createBackup({bool share = true});
  Future<BackupInfo> validateBackupFile(String filePath);
  Future<void> restoreBackup(String filePath);
  Future<BackupInfo?> getLastBackupInfo();
  Future<List<BackupInfo>> getLocalBackups();
  Future<void> shareBackup(String filePath);
  Future<void> deleteBackup(String filePath);
}

class BackupSourceImpl implements BackupSource {
  final AppDatabase db;
  final FlutterSecureStorage secureStorage;
  final NotificationService notificationService;
  final Future<void> Function()? onReinitializeDatabase;

  static const String keyLastBackupAt = 'last_backup_at';

  BackupSourceImpl({
    required this.db,
    required this.secureStorage,
    required this.notificationService,
    this.onReinitializeDatabase,
  });

  Future<Directory> _getBackupsDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory(p.join(docsDir.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    return backupsDir;
  }

  Future<File> _getDatabaseFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, 'gym_management_app.sqlite'));
  }

  Future<Directory> _getPhotosDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(docsDir.path, 'member_photos'));
  }

  @override
  Future<BackupInfo> createBackup({bool share = true}) async {
    // 1. Force WAL checkpoint to flush all data into the main sqlite file
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

    final dbFile = await _getDatabaseFile();
    if (!await dbFile.exists()) {
      throw const FileSystemException('قاعدة البيانات غير موجودة على الجهاز.');
    }

    final dbBytes = await dbFile.readAsBytes();
    final dbChecksum = sha256.convert(dbBytes).toString();

    // 2. Query member count
    final memberCountQuery = await (db.selectOnly(db.members)
          ..addColumns([db.members.id.count()]))
        .map((row) => row.read(db.members.id.count()) ?? 0)
        .getSingle();

    final now = DateTime.now();
    final manifestMap = {
      'app_version': '1.0.0+1',
      'schema_version': db.schemaVersion,
      'created_at': now.toUtc().toIso8601String(),
      'member_count': memberCountQuery,
      'checksum': dbChecksum,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifestMap));

    // 3. Collect photos
    final photosDir = await _getPhotosDirectory();
    final entries = <BackupZipEntry>[
      BackupZipEntry('manifest.json', manifestBytes),
      BackupZipEntry('database.sqlite', dbBytes),
    ];

    if (await photosDir.exists()) {
      final photoFiles = photosDir.listSync().whereType<File>();
      for (final photo in photoFiles) {
        final photoBytes = await photo.readAsBytes();
        entries.add(
          BackupZipEntry('photos/${p.basename(photo.path)}', photoBytes),
        );
      }
    }

    // 4. Run zip encoding off the UI thread with compute
    final zipBytes = await compute(_encodeZipIsolate, entries);

    // 5. Save to local backups directory: gym_backup_YYYYMMDD_HHmm.gymbak
    final backupsDir = await _getBackupsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(now);
    final fileName = 'gym_backup_$timestamp.gymbak';
    var targetFile = File(p.join(backupsDir.path, fileName));
    if (await targetFile.exists()) {
      final disambiguated = 'gym_backup_${timestamp}_${now.second}.gymbak';
      targetFile = File(p.join(backupsDir.path, disambiguated));
    }

    await targetFile.writeAsBytes(zipBytes, flush: true);

    // 6. Keep only the last 3 local backups
    await _pruneOldBackups(backupsDir);

    // 7. Save last backup timestamp
    await secureStorage.write(key: keyLastBackupAt, value: now.toIso8601String());

    final backupInfo = BackupInfo(
      filePath: targetFile.path,
      fileName: p.basename(targetFile.path),
      createdAt: now,
      memberCount: memberCountQuery,
      appVersion: '1.0.0+1',
      schemaVersion: db.schemaVersion,
      databaseChecksum: dbChecksum,
      fileSizeBytes: zipBytes.length,
    );

    // 8. Open share sheet if requested
    if (share) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(targetFile.path)],
          text: 'نسخة احتياطية لتطبيق إدارة الجيم - $fileName',
        ),
      );
    }

    return backupInfo;
  }

  Future<void> _pruneOldBackups(Directory backupsDir) async {
    try {
      final files = backupsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.gymbak'))
          .toList();

      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (files.length > 3) {
        for (int i = 3; i < files.length; i++) {
          try {
            await files[i].delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  Future<BackupInfo> validateBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileSystemException('ملف النسخة الاحتياطية غير موجود.');
    }

    final bytes = await file.readAsBytes();
    final extracted = await compute(_decodeZipIsolate, bytes);

    final Map<String, dynamic> manifest;
    try {
      manifest = jsonDecode(extracted.manifestJson) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('ملف البيان (manifest.json) تالف وغير قابل للقراءة.');
    }

    final manifestChecksum = manifest['checksum'] as String? ?? '';
    final actualChecksum = sha256.convert(extracted.dbBytes).toString();
    if (manifestChecksum.isEmpty || manifestChecksum != actualChecksum) {
      throw const FormatException('فشل التحقق من صحة النسخة الاحتياطية: البصمة الإلكترونية غير متطابقة (الملف تالف).');
    }

    final backupSchema = (manifest['schema_version'] as num?)?.toInt() ?? 0;
    if (backupSchema > db.schemaVersion) {
      throw FormatException(
        'نسخة قاعدة البيانات أحدث من إصدار التطبيق الحالي ($backupSchema > ${db.schemaVersion}). يرجى تحديث التطبيق أولاً.',
      );
    }

    return BackupInfo.fromManifest(
      manifest: manifest,
      filePath: filePath,
      fileName: p.basename(filePath),
      fileSizeBytes: bytes.length,
    );
  }

  @override
  Future<void> restoreBackup(String filePath) async {
    // 1. Validate file before proceeding
    final backupFile = File(filePath);
    if (!await backupFile.exists()) {
      throw const FileSystemException('ملف النسخة الاحتياطية غير موجود.');
    }

    final bytes = await backupFile.readAsBytes();
    final extracted = await compute(_decodeZipIsolate, bytes);

    final Map<String, dynamic> manifest =
        jsonDecode(extracted.manifestJson) as Map<String, dynamic>;
    final manifestChecksum = manifest['checksum'] as String? ?? '';
    final actualChecksum = sha256.convert(extracted.dbBytes).toString();
    if (manifestChecksum != actualChecksum) {
      throw const FormatException('فشل التحقق من صحة النسخة الاحتياطية: البصمة الإلكترونية غير متطابقة.');
    }

    final backupSchema = (manifest['schema_version'] as num?)?.toInt() ?? 0;
    if (backupSchema > db.schemaVersion) {
      throw FormatException(
        'نسخة قاعدة البيانات أحدث من إصدار التطبيق الحالي ($backupSchema > ${db.schemaVersion}). يرجى تحديث التطبيق أولاً.',
      );
    }

    // 2. Take automatic safety backup of current data first
    final dbFile = await _getDatabaseFile();
    final photosDir = await _getPhotosDirectory();
    final backupsDir = await _getBackupsDirectory();
    final safetyBackupFile = File(p.join(backupsDir.path, '_safety_backup_before_restore.gymbak'));

    List<int>? safetyBackupBytes;
    if (await dbFile.exists()) {
      try {
        await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
        final currentDbBytes = await dbFile.readAsBytes();
        final currentChecksum = sha256.convert(currentDbBytes).toString();
        final safetyManifest = utf8.encode(jsonEncode({
          'app_version': '1.0.0+1',
          'schema_version': db.schemaVersion,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'member_count': 0,
          'checksum': currentChecksum,
        }));

        final safetyEntries = <BackupZipEntry>[
          BackupZipEntry('manifest.json', safetyManifest),
          BackupZipEntry('database.sqlite', currentDbBytes),
        ];

        if (await photosDir.exists()) {
          for (final photo in photosDir.listSync().whereType<File>()) {
            safetyEntries.add(
              BackupZipEntry('photos/${p.basename(photo.path)}', await photo.readAsBytes()),
            );
          }
        }

        final encodedSafety = await compute(_encodeZipIsolate, safetyEntries);
        safetyBackupBytes = encodedSafety;
        await safetyBackupFile.writeAsBytes(encodedSafety, flush: true);
      } catch (_) {}
    }

    // 3. Close the database
    await db.close();
    await Future.delayed(const Duration(milliseconds: 60));

    try {
      // 4. Remove current db files (sqlite, wal, shm)
      final walFile = File('${dbFile.path}-wal');
      final shmFile = File('${dbFile.path}-shm');
      if (await dbFile.exists()) await dbFile.delete();
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();

      // 5. Write restored database file
      await dbFile.writeAsBytes(extracted.dbBytes, flush: true);

      // 6. Replace photos
      if (await photosDir.exists()) {
        try {
          await photosDir.delete(recursive: true);
        } catch (_) {}
      }
      await photosDir.create(recursive: true);

      for (final photoEntry in extracted.photos) {
        final photoFileName = p.basename(photoEntry.path);
        final destPhoto = File(p.join(photosDir.path, photoFileName));
        await destPhoto.writeAsBytes(photoEntry.bytes, flush: true);
      }

      // 7. Reopen database and rerun migrations
      if (onReinitializeDatabase != null) {
        await onReinitializeDatabase!();
      }

      // 8. Re-seed notification schedules
      await _reseedNotifications();

      // Delete safety backup on success
      if (await safetyBackupFile.exists()) {
        await safetyBackupFile.delete();
      }
    } catch (restoreError) {
      // Rollback from safety backup
      if (safetyBackupBytes != null) {
        try {
          final rollbackData = await compute(_decodeZipIsolate, safetyBackupBytes);
          final walFile = File('${dbFile.path}-wal');
          final shmFile = File('${dbFile.path}-shm');
          if (await dbFile.exists()) await dbFile.delete();
          if (await walFile.exists()) await walFile.delete();
          if (await shmFile.exists()) await shmFile.delete();
          await dbFile.writeAsBytes(rollbackData.dbBytes, flush: true);

          if (await photosDir.exists()) {
            await photosDir.delete(recursive: true);
          }
          await photosDir.create(recursive: true);
          for (final photoEntry in rollbackData.photos) {
            final destPhoto = File(p.join(photosDir.path, p.basename(photoEntry.path)));
            await destPhoto.writeAsBytes(photoEntry.bytes, flush: true);
          }

          if (onReinitializeDatabase != null) {
            await onReinitializeDatabase!();
          }
        } catch (_) {}
      }

      throw Exception('فشلت عملية الاستعادة وتم استرجاع البيانات السابقة: $restoreError');
    }
  }

  Future<void> _reseedNotifications() async {
    try {
      await notificationService.cancelAll();
      final now = DateTime.now();

      final activeSubs = await (db.select(db.subscriptions)
            ..where((s) => s.endDate.isBiggerThanValue(now) & s.status.equals('active')))
          .join([
        innerJoin(db.members, db.members.id.equalsExp(db.subscriptions.memberId)),
      ]).get();

      for (final row in activeSubs) {
        final sub = row.readTable(db.subscriptions);
        final member = row.readTable(db.members);
        if (sub.status == 'active' && !member.isSuspended) {
          await notificationService.scheduleSubscriptionExpiry(
            subscriptionId: sub.id,
            memberName: member.name,
            endDate: sub.endDate,
          );
        }
      }
    } catch (e) {
      debugPrint('Error reseeding notifications: $e');
    }
  }

  @override
  Future<BackupInfo?> getLastBackupInfo() async {
    final localBackups = await getLocalBackups();
    if (localBackups.isNotEmpty) {
      return localBackups.first;
    }

    final storedDateStr = await secureStorage.read(key: keyLastBackupAt);
    if (storedDateStr != null) {
      final date = DateTime.tryParse(storedDateStr);
      if (date != null) {
        return BackupInfo(
          filePath: '',
          fileName: '',
          createdAt: date,
          memberCount: 0,
          appVersion: '1.0.0+1',
          schemaVersion: db.schemaVersion,
          databaseChecksum: '',
          fileSizeBytes: 0,
        );
      }
    }
    return null;
  }

  @override
  Future<List<BackupInfo>> getLocalBackups() async {
    final backupsDir = await _getBackupsDirectory();
    final files = backupsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.gymbak') && !p.basename(f.path).startsWith('_'))
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    final list = <BackupInfo>[];
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final manifestFile = archive.findFile('manifest.json');
        if (manifestFile != null) {
          final jsonStr = utf8.decode(manifestFile.content as List<int>);
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          list.add(
            BackupInfo.fromManifest(
              manifest: map,
              filePath: file.path,
              fileName: p.basename(file.path),
              fileSizeBytes: bytes.length,
            ),
          );
        }
      } catch (_) {
        // Skip unparseable backups
      }
    }
    return list;
  }

  @override
  Future<void> shareBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileSystemException('الملف المحدد غير موجود.');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'نسخة احتياطية لتطبيق إدارة الجيم - ${p.basename(filePath)}',
      ),
    );
  }

  @override
  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
