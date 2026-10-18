import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Displays a confirmation alert dialog before exiting the application.
/// Returns `true` if the user confirms exit, `false` or `null` if cancelled.
Future<bool?> showExitConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: AppColors.overlay,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      icon: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.errorTint,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.logout_rounded,
          color: AppColors.error,
          size: 28,
        ),
      ),
      title: Text(
        'الخروج من التطبيق',
        style: AppTextStyles.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: Text(
        'هل أنت متأكد من رغبتك في إغلاق التطبيق؟',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('خروج'),
        ),
      ],
    ),
  );
}
