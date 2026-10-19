import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/widgets/image_preview_dialog.dart';
import 'member_avatar.dart';

class MemberPhotoPicker extends StatelessWidget {
  final String? existingPhotoPath;
  final File? newPhotoFile;
  final String name;
  final ValueChanged<File> onPhotoSelected;
  final VoidCallback onPhotoRemoved;

  const MemberPhotoPicker({
    super.key,
    this.existingPhotoPath,
    this.newPhotoFile,
    required this.name,
    required this.onPhotoSelected,
    required this.onPhotoRemoved,
  });

  Future<File?> _cropImage(String sourcePath) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'تعديل وقص الصورة',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
          IOSUiSettings(
            title: 'تعديل وقص الصورة',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
        ],
      );

      if (cropped != null) {
        return File(cropped.path);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _showPickerBottomSheet(BuildContext context) async {
    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'تغيير صورة المشترك',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'التقاط صورة بالكاميرا',
                      style: AppTextStyles.bodyLarge,
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final photo = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1200,
                        maxHeight: 1200,
                        imageQuality: 85,
                      );
                      if (photo != null) {
                        final cropped = await _cropImage(photo.path);
                        if (cropped != null) {
                          onPhotoSelected(cropped);
                        }
                      }
                    },
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'اختيار من المعرض',
                      style: AppTextStyles.bodyLarge,
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final photo = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1200,
                        maxHeight: 1200,
                        imageQuality: 85,
                      );
                      if (photo != null) {
                        final cropped = await _cropImage(photo.path);
                        if (cropped != null) {
                          onPhotoSelected(cropped);
                        }
                      }
                    },
                  ),
                ),
                if (newPhotoFile != null || (existingPhotoPath != null && existingPhotoPath!.isNotEmpty)) ...[
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(
                        Icons.fullscreen_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'عرض الصورة بالحجم الكامل',
                        style: AppTextStyles.bodyLarge,
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ImagePreviewDialog.show(
                          context,
                          file: newPhotoFile,
                          imagePath: existingPhotoPath,
                          title: name.isNotEmpty ? name : 'صورة المشترك',
                        );
                      },
                    ),
                  ),
                  const Divider(color: AppColors.border),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                      title: Text(
                        'حذف الصورة',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onPhotoRemoved();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = newPhotoFile != null ||
        (existingPhotoPath != null && existingPhotoPath!.isNotEmpty);

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Tooltip(
            message: hasPhoto ? 'اضغط لعرض الصورة بحجم أكبر' : 'إضافة صورة للمشترك',
            child: MemberAvatar(
              photoFile: newPhotoFile,
              photoPath: existingPhotoPath,
              name: name.isNotEmpty ? name : '؟',
              size: 96,
              enablePreview: false,
              onTap: hasPhoto
                  ? () {
                      ImagePreviewDialog.show(
                        context,
                        file: newPhotoFile,
                        imagePath: existingPhotoPath,
                        title: name.isNotEmpty ? name : 'صورة المشترك',
                      );
                    }
                  : () => _showPickerBottomSheet(context),
            ),
          ),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _showPickerBottomSheet(context),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
