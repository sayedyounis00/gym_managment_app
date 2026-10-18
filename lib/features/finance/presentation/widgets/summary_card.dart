import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/finance_summary.dart';

class FinanceSummaryCard extends StatelessWidget {
  final FinanceSummary summary;

  const FinanceSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(27, 33, 48, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCell(
              label: 'الإيرادات',
              amount: summary.revenue,
              color: AppColors.success,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(
            height: 48,
            width: 1,
            color: AppColors.border,
          ),
          Expanded(
            child: _buildCell(
              label: 'المصروفات',
              amount: summary.expenses,
              color: AppColors.error,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(
            height: 48,
            width: 1,
            color: AppColors.border,
          ),
          Expanded(
            child: _buildCell(
              label: 'الصافي (تقديري)',
              amount: summary.net,
              color: summary.net >= 0 ? AppColors.primary : AppColors.error,
              icon: summary.net >= 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(amount),
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
