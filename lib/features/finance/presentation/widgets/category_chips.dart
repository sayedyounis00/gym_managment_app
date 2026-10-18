import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/finance_enums.dart';

class ExpenseCategoryChips extends StatelessWidget {
  final ExpenseCategory selectedCategory;
  final ValueChanged<ExpenseCategory> onSelected;

  const ExpenseCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'تصنيف المصروف',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: ExpenseCategory.values.map((category) {
            final isSelected = category == selectedCategory;

            return InkWell(
              onTap: () => onSelected(category),
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.errorTint : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected ? AppColors.error : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : category.icon,
                      size: 17,
                      color: isSelected ? AppColors.error : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      category.labelArabic,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? AppColors.error : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
