import 'dart:io';
import 'package:path_provider/path_provider.dart';

abstract class ImageStorageService {
  Future<String> saveMemberPhoto({
    required File sourceFile,
    required int memberId,
    String? oldRelativePath,
  });

  Future<void> deletePhoto(String relativePath);

  Future<File?> getPhotoFile(String? relativePath);
}

class ImageStorageServiceImpl implements ImageStorageService {
  static String? _cachedDocsDirPath;

  static Future<String> getDocsDirPath() async {
    return _cachedDocsDirPath ??= (await getApplicationDocumentsDirectory()).path;
  }

  static String? get cachedDocsDirPath => _cachedDocsDirPath;

  @override
  Future<String> saveMemberPhoto({
    required File sourceFile,
    required int memberId,
    String? oldRelativePath,
  }) async {
    final docsPath = await getDocsDirPath();
    final photosDir = Directory('$docsPath/member_photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    if (oldRelativePath != null && oldRelativePath.isNotEmpty) {
      await deletePhoto(oldRelativePath);
    }

    final originalPath = sourceFile.path;
    final dotIndex = originalPath.lastIndexOf('.');
    final ext = dotIndex != -1 ? originalPath.substring(dotIndex) : '.jpg';
    final fileName = 'member_${memberId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destinationPath = '${photosDir.path}/$fileName';

    await sourceFile.copy(destinationPath);

    return 'member_photos/$fileName';
  }

  @override
  Future<void> deletePhoto(String relativePath) async {
    try {
      final docsPath = await getDocsDirPath();
      final fullPath = '$docsPath/$relativePath';
      final file = File(fullPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore deletion errors for missing or locked files
    }
  }

  @override
  Future<File?> getPhotoFile(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return null;
    try {
      final docsPath = await getDocsDirPath();
      final fullPath = '$docsPath/$relativePath';
      final file = File(fullPath);
      if (await file.exists()) {
        return file;
      }
    } catch (_) {}
    return null;
  }
}
