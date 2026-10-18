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
  @override
  Future<String> saveMemberPhoto({
    required File sourceFile,
    required int memberId,
    String? oldRelativePath,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/member_photos');
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
      final docsDir = await getApplicationDocumentsDirectory();
      final fullPath = '${docsDir.path}/$relativePath';
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
      final docsDir = await getApplicationDocumentsDirectory();
      final fullPath = '${docsDir.path}/$relativePath';
      final file = File(fullPath);
      if (await file.exists()) {
        return file;
      }
    } catch (_) {}
    return null;
  }
}
