import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class PaymentMethodChips extends StatelessWidget {
  final String selectedMethod; // 'cash' | 'transfer' | 'wallet'
  final ValueChanged<String> onSelected;

  const PaymentMethodChips({
    super.key,
    required this.selectedMethod,
    required this.onSelected,
  });

  static const List<Map<String, dynamic>> _methods = [
    {
      'id': 'cash',
      'label': 'نقدي',
      'icon': Icons.payments_rounded,
    },
    {
      'id': 'transfer',
      'label': 'تحويل',
      'icon': Icons.swap_horiz_rounded,
    },
    {
      'id': 'wallet',
      'label': 'محفظة إلكترونية',
      'icon': Icons.account_balance_wallet_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'طريقة الدفع',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _methods.map((method) {
            final isSelected = method['id'] == selectedMethod;

            return InkWell(
              onTap: () => onSelected(method['id'] as String),
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
                      isSelected ? Icons.check_circle_rounded : (method['icon'] as IconData),
                      size: 16,
                      color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      method['label'] as String,
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
