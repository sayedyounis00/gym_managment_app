import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/segmented_selector.dart';
import '../cubit/reports/reports_cubit.dart';
import '../cubit/reports/reports_state.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReportsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportsCubit>()..load(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  void _showExportOptions(BuildContext context, ReportsCubit cubit) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'خيارات التصدير والمشاركة',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                  ),
                  title: const Text('تقرير PDF منسق للطباعة والمشاركة'),
                  subtitle: const Text('يتضمن ملخص الشهر وجدول المعاملات'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final path = await cubit.exportPdf();
                    if (path != null) {
                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(path)],
                          text: 'التقرير المالي',
                        ),
                      );
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successTint,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: AppColors.success),
                  ),
                  title: const Text('ملف بيانات CSV (إكسل)'),
                  subtitle: const Text('لتصدير المعاملات والتحليل الخارجي'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final path = await cubit.exportCsv();
                    if (path != null) {
                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(path)],
                          text: 'ملف الحسابات CSV',
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        final cubit = context.read<ReportsCubit>();
        final monthLabel = DateFormat('MMMM yyyy', 'ar').format(state.selectedMonth);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('التقارير المالية', style: AppTextStyles.titleLarge),
            backgroundColor: AppColors.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'تصدير التقرير',
                onPressed: () => _showExportOptions(context, cubit),
              ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Range Mode Selector
                      SegmentedSelector<String>(
                        segments: const [
                          SegmentItem(value: 'day', label: 'اليوم'),
                          SegmentItem(value: 'week', label: 'آخر 7 أيام'),
                          SegmentItem(value: 'month', label: 'هذا الشهر'),
                        ],
                        selectedValue: state.rangeMode,
                        onSelected: (mode) => cubit.setRangeMode(mode),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Month Title & Summary Bar
                      Text(
                        'ملخص $monthLabel',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('الإيرادات', state.summary.revenue, AppColors.success),
                            Container(height: 36, width: 1, color: AppColors.border),
                            _buildStatItem('المصروفات', state.summary.expenses, AppColors.error),
                            Container(height: 36, width: 1, color: AppColors.border),
                            _buildStatItem(
                              'صافي الربح',
                              state.summary.net,
                              state.summary.net >= 0 ? AppColors.primary : AppColors.error,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Chart Card
                      Text(
                        'الرسم البياني (الإيرادات مقابل المصروفات)',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 260,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: state.dailyTotals.isEmpty
                            ? Center(
                                child: Text(
                                  'لا توجد حركات كافية لعرض الرسم البياني',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
                                ),
                              )
                            : _buildChart(state.dailyTotals),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Export CTA Button
                      AppButton.outlined(
                        label: state.isExporting ? 'جارِ التصدير...' : 'تصدير ومشاركة التقرير (PDF / CSV)',
                        icon: Icons.download_rounded,
                        height: 52,
                        isLoading: state.isExporting,
                        onPressed: () => _showExportOptions(context, cubit),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.format(amount),
          style: AppTextStyles.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List dailyTotals) {
    final bars = <BarChartGroupData>[];
    double maxY = 100.0;

    for (int i = 0; i < dailyTotals.length; i++) {
      final total = dailyTotals[i];
      final rev = total.revenue as double;
      final exp = total.expenses as double;

      if (rev > maxY) maxY = rev;
      if (exp > maxY) maxY = exp;

      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: rev,
              color: AppColors.chartRevenue,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            BarChartRodData(
              toY: exp,
              color: AppColors.chartExpenses,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY * 1.15,
        barGroups: bars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4).clamp(1.0, double.infinity),
          getDrawingHorizontalLine: (val) => const FlLine(
            color: AppColors.chartGrid,
            dashArray: [4, 4],
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (val, meta) {
                return Text(
                  CurrencyFormatter.formatCompact(val),
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= dailyTotals.length) return const SizedBox.shrink();
                final date = dailyTotals[idx].date as DateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('d/M').format(date),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
