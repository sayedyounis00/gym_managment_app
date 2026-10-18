import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

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
    final formattedDate = DateFormat('d MMMM yyyy', 'ar').format(value);

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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!readOnly)
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary,
                  ),
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
