import 'package:equatable/equatable.dart';

class BackupInfo extends Equatable {
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final int memberCount;
  final String appVersion;
  final int schemaVersion;
  final String databaseChecksum;
  final int fileSizeBytes;

  const BackupInfo({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.memberCount,
    required this.appVersion,
    required this.schemaVersion,
    required this.databaseChecksum,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toManifestJson() {
    return {
      'app_version': appVersion,
      'schema_version': schemaVersion,
      'created_at': createdAt.toIso8601String(),
      'member_count': memberCount,
      'checksum': databaseChecksum,
    };
  }

  factory BackupInfo.fromManifest({
    required Map<String, dynamic> manifest,
    required String filePath,
    required String fileName,
    required int fileSizeBytes,
  }) {
    return BackupInfo(
      filePath: filePath,
      fileName: fileName,
      createdAt: DateTime.parse(manifest['created_at'] as String),
      memberCount: (manifest['member_count'] as num).toInt(),
      appVersion: manifest['app_version'] as String? ?? '1.0.0',
      schemaVersion: (manifest['schema_version'] as num).toInt(),
      databaseChecksum: manifest['checksum'] as String? ?? '',
      fileSizeBytes: fileSizeBytes,
    );
  }

  @override
  List<Object?> get props => [
        filePath,
        fileName,
        createdAt,
        memberCount,
        appVersion,
        schemaVersion,
        databaseChecksum,
        fileSizeBytes,
      ];
}
