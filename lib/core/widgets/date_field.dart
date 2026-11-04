import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/date_utils.dart';

class DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime>? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool readOnly;
  final String? helperText;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.readOnly = false,
    this.helperText,
  });

  Future<void> _pickDate(BuildContext context) async {
    if (readOnly || onChanged == null) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = AppDateUtils.formatShortDate(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        InkWell(
          onTap: readOnly ? null : () => _pickDate(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
            decoration: BoxDecoration(
              color: readOnly ? AppColors.surfaceVariant.withValues(alpha: 0.6) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      formattedDate,
                      maxLines: 1,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helperText!,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
