import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'تأكيد',
    this.cancelLabel = 'إلغاء',
    this.isDestructive = false,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'تأكيد',
    String cancelLabel = 'إلغاء',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (ctx) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: AppSpacing.sm,
                overflowSpacing: AppSpacing.sm,
                overflowAlignment: OverflowBarAlignment.end,
                children: [
                  AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.text,
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
                      } else {
                        Navigator.of(context).pop(false);
                      }
                    },
                  ),
                  AppButton(
                    label: confirmLabel,
                    variant: isDestructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    onPressed: onConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
