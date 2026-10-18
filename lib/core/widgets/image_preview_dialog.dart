import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class ImagePreviewDialog extends StatefulWidget {
  final File? file;
  final String? imagePath;
  final String title;

  const ImagePreviewDialog({
    super.key,
    this.file,
    this.imagePath,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    File? file,
    String? imagePath,
    required String title,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => ImagePreviewDialog(
        file: file,
        imagePath: imagePath,
        title: title,
      ),
    );
  }

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  File? _resolvedFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.file != null) {
      _resolvedFile = widget.file;
      _isLoading = false;
    } else {
      _resolveFile();
    }
  }

  Future<void> _resolveFile() async {
    if (widget.file != null) {
      if (mounted) {
        setState(() {
          _resolvedFile = widget.file;
          _isLoading = false;
        });
      }
      return;
    }

    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final file = File('${docsDir.path}/${widget.imagePath!}');
        if (await file.exists()) {
          if (mounted) {
            setState(() {
              _resolvedFile = file;
              _isLoading = false;
            });
          }
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _resolvedFile = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 650,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'إغلاق',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Interactive zoomable image container
                Flexible(
                  child: Container(
                    color: Colors.black87,
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 280,
                      maxHeight: 480,
                    ),
                    child: _buildImageContent(),
                  ),
                ),

                // Footer hint
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.pinch_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'يمكنك التكبير والتصغير بإصبعين',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_resolvedFile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_rounded,
              size: 48,
              color: Colors.white54,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'تعذر تحميل الصورة',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Image.file(
          _resolvedFile!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              'خطأ في عرض الصورة',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
