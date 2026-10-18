import 'package:flutter/material.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';

class BodyStatsCard extends StatelessWidget {
  final int? age;
  final double? weightKg;
  final double? heightCm;

  const BodyStatsCard({
    super.key,
    this.age,
    this.weightKg,
    this.heightCm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCell(
              label: 'العمر',
              value: age != null ? '$age' : '--',
              unit: 'سنة',
              icon: Icons.cake_rounded,
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: AppColors.border,
          ),
          Expanded(
            child: _buildStatCell(
              label: 'الوزن',
              value: weightKg != null ? weightKg!.toStringAsFixed(weightKg! % 1 == 0 ? 0 : 1) : '--',
              unit: 'كجم',
              icon: Icons.monitor_weight_rounded,
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: AppColors.border,
          ),
          Expanded(
            child: _buildStatCell(
              label: 'الطول',
              value: heightCm != null ? heightCm!.toStringAsFixed(heightCm! % 1 == 0 ? 0 : 1) : '--',
              unit: 'سم',
              icon: Icons.height_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
