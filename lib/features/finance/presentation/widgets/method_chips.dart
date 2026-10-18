import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/finance_enums.dart';

class FinanceMethodChips extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod?> onSelected;
  final bool allowClear;

  const FinanceMethodChips({
    super.key,
    required this.selectedMethod,
    required this.onSelected,
    this.allowClear = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'طريقة الدفع (اختياري)',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: PaymentMethod.values.map((method) {
            final isSelected = method == selectedMethod;

            return InkWell(
              onTap: () {
                if (isSelected && allowClear) {
                  onSelected(null);
                } else {
                  onSelected(method);
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 38,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : method.icon,
                      size: 16,
                      color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      method.labelArabic,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
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
