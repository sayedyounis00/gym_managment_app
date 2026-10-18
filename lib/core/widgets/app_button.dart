import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  destructive,
  destructiveOutlined,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    IconData? leadingIcon,
    IconData? icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 52.0,
    this.padding,
  }) : leadingIcon = icon ?? leadingIcon;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    IconData? leadingIcon,
    IconData? icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 52.0,
    this.padding,
  })  : variant = AppButtonVariant.outlined,
        leadingIcon = icon ?? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    Widget childContent;
    if (isLoading) {
      childContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getLoadingColor(),
          ),
        ),
      );
    } else {
      final textWidget = Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: _getTextColor(),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

      if (leadingIcon != null || trailingIcon != null) {
        childContent = Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: _getTextColor()),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(child: textWidget),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(trailingIcon, size: 18, color: _getTextColor()),
            ],
          ],
        );
      } else {
        childContent = textWidget;
      }
    }

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.surfaceVariant,
            disabledForegroundColor: AppColors.textDisabled,
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
            shape: shape,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.secondary:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primaryDark,
            disabledBackgroundColor: AppColors.surfaceVariant,
            disabledForegroundColor: AppColors.textDisabled,
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
            shape: shape,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
            shape: shape,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 48, height),
            shape: shape,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.destructive:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surfaceVariant,
            disabledForegroundColor: AppColors.textDisabled,
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
            shape: shape,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.destructiveOutlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error, width: 1.5),
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
            shape: shape,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: childContent,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Color _getTextColor() {
    if (onPressed == null) return AppColors.textDisabled;
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.onPrimary;
      case AppButtonVariant.secondary:
        return AppColors.primaryDark;
      case AppButtonVariant.outlined:
        return AppColors.secondary;
      case AppButtonVariant.text:
        return AppColors.primary;
      case AppButtonVariant.destructive:
        return Colors.white;
      case AppButtonVariant.destructiveOutlined:
        return AppColors.error;
    }
  }

  Color _getLoadingColor() {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        return Colors.white;
      case AppButtonVariant.secondary:
        return AppColors.primaryDark;
      case AppButtonVariant.outlined:
        return AppColors.secondary;
      case AppButtonVariant.text:
        return AppColors.primary;
      case AppButtonVariant.destructiveOutlined:
        return AppColors.error;
    }
  }
}
