import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SegmentItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SegmentItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class SegmentedSelector<T> extends StatelessWidget {
  final List<SegmentItem<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const SegmentedSelector({
    super.key,
    required this.segments,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: segments.map((seg) {
          final isSelected = seg.value == selectedValue;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(seg.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (seg.icon != null) ...[
                      Icon(
                        seg.icon,
                        size: 16,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(
                      seg.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
