import 'package:flutter/material.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/utils/currency_formatter.dart';
import '../../domain/entities/membership_package.dart';

class PackageCard extends StatelessWidget {
  final MembershipPackage package;
  final VoidCallback onEdit;
  final ValueChanged<bool>? onToggleActive;

  const PackageCard({
    super.key,
    required this.package,
    required this.onEdit,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isInactive = !package.isActive;

    return Container(
      decoration: BoxDecoration(
        color: isInactive ? AppColors.surfaceVariant.withValues(alpha: 0.5) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isInactive ? AppColors.borderStrong : AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row: Name + Badge + Edit Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.name,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isInactive ? AppColors.textDisabled : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs - 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryLight,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  'مدة',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs + 2),
                              Flexible(
                                child: Text(
                                  package.formattedDuration,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isInactive ? AppColors.textDisabled : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (isInactive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'غير مفعلة',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textDisabled,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Semantics(
                      label: 'تعديل باقة ${package.name}',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        color: AppColors.textSecondary,
                        tooltip: 'تعديل الباقة',
                        onPressed: onEdit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.md),

                // Bottom row: Price and Active switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'السعر',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              CurrencyFormatter.format(package.price),
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: isInactive ? AppColors.textDisabled : AppColors.primary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onToggleActive != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            package.isActive ? 'مفعلة' : 'معطلة',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: package.isActive ? AppColors.primary : AppColors.textDisabled,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Semantics(
                            label: 'تبديل حالة تفعيل باقة ${package.name}',
                            child: Switch(
                              value: package.isActive,
                              onChanged: onToggleActive,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
