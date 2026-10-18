import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

class FinanceSummaryCard extends StatelessWidget {
  final double revenue;
  final double expenses;
  final double todayRevenue;
  final VoidCallback? onTap;

  const FinanceSummaryCard({
    super.key,
    required this.revenue,
    required this.expenses,
    required this.todayRevenue,
    this.onTap,
  });

  double get netProfit => revenue - expenses;

  @override
  Widget build(BuildContext context) {
    final isProfitPositive = netProfit >= 0;
    final maxY = max(max(revenue, expenses), 10.0) * 1.25;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final cardPadding = isNarrow ? AppSpacing.md : AppSpacing.lg;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Ink(
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(27, 33, 48, 0.04),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Flexible & Wrapping support
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Icon(
                                Symbols.account_balance_wallet_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                'ملخص الحسابات',
                                style: AppTextStyles.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (todayRevenue > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successTint,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'اليوم: ${CurrencyFormatter.formatCompact(todayRevenue)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Hero Net Profit Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: isProfitPositive ? AppColors.heroGradient : null,
                      color: isProfitPositive ? null : AppColors.error,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'صافي الأرباح (الشهر الحالي)',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.format(netProfit),
                            style: AppTextStyles.displayLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2-Metric breakdown
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          label: 'الإيرادات',
                          amount: revenue,
                          color: AppColors.success,
                          icon: Symbols.arrow_upward_rounded,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          label: 'المصروفات',
                          amount: expenses,
                          color: AppColors.error,
                          icon: Symbols.arrow_downward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Bar chart
                  SizedBox(
                    height: 110,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final label = group.x == 0 ? 'الإيرادات' : 'المصروفات';
                              return BarTooltipItem(
                                '$label\n${CurrencyFormatter.format(rod.toY)}',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final style = AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                );
                                if (value.toInt() == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('الإيرادات', style: style),
                                  );
                                } else if (value.toInt() == 1) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('المصروفات', style: style),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: revenue,
                                color: AppColors.chartRevenue,
                                width: isNarrow ? 24 : 28,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.sm),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: expenses,
                                color: AppColors.chartExpenses,
                                width: isNarrow ? 24 : 28,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.sm),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.formatCompact(amount),
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}
