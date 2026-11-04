import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PinPad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onClearPressed;

  const PinPad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: AppSpacing.xs + 2),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: AppSpacing.xs + 2),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: AppSpacing.xs + 2),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildDigitButton(digit)).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onDigitPressed(digit);
        },
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            digit,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Clear Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onClearPressed();
            },
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              child: Text(
                'مسح',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        // 0 Button
        _buildDigitButton('0'),
        // Backspace Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onDeletePressed();
            },
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              child: const Icon(
                Icons.backspace_outlined,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
