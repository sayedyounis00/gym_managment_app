import 'package:flutter/material.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';

class MemberFilterBar extends StatelessWidget {
  final MemberStatusType? selectedFilter;
  final ValueChanged<MemberStatusType?> onFilterSelected;

  const MemberFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final barHeight = (38.0 * textScale).clamp(38.0, 52.0);
    final chipHeight = (36.0 * textScale).clamp(36.0, 48.0);

    return SizedBox(
      height: barHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            _buildChip(
              label: 'الكل',
              isSelected: selectedFilter == null,
              onTap: () => onFilterSelected(null),
              chipHeight: chipHeight,
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildChip(
              label: 'نشط',
              isSelected: selectedFilter == MemberStatusType.active,
              onTap: () => onFilterSelected(MemberStatusType.active),
              chipHeight: chipHeight,
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildChip(
              label: 'ينتهي قريباً',
              isSelected: selectedFilter == MemberStatusType.expiringSoon,
              onTap: () => onFilterSelected(MemberStatusType.expiringSoon),
              chipHeight: chipHeight,
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildChip(
              label: 'منتهي',
              isSelected: selectedFilter == MemberStatusType.expired,
              onTap: () => onFilterSelected(MemberStatusType.expired),
              chipHeight: chipHeight,
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildChip(
              label: 'موقوف',
              isSelected: selectedFilter == MemberStatusType.paused,
              onTap: () => onFilterSelected(MemberStatusType.paused),
              chipHeight: chipHeight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required double chipHeight,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          height: chipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
