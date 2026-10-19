import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class PaginatedBottomLoader extends StatelessWidget {
  final bool isLoading;
  final String? loadingText;
  final EdgeInsetsGeometry padding;

  const PaginatedBottomLoader({
    super.key,
    required this.isLoading,
    this.loadingText,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(27, 33, 48, 0.05),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                loadingText ?? 'جاري تحميل المزيد...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
