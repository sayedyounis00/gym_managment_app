import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/paginated_bottom_loader.dart';
import '../../../../core/widgets/segmented_selector.dart';
import '../../domain/entities/daily_total.dart';
import '../../domain/entities/finance_enums.dart';
import '../../domain/entities/finance_summary.dart';
import '../../domain/entities/ledger_entry.dart';
import '../cubit/balances/balances_cubit.dart';
import '../cubit/balances/balances_state.dart';
import '../cubit/finance_overview/finance_overview_cubit.dart';
import '../cubit/finance_overview/finance_overview_state.dart';
import '../cubit/ledger/ledger_cubit.dart';
import '../cubit/ledger/ledger_state.dart';
import '../widgets/add_choice_sheet.dart';
import '../widgets/add_payment_sheet.dart';
import '../widgets/balance_tile.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/void_dialog.dart';
import 'add_expense_page.dart';
import 'reports_page.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<FinanceOverviewCubit>()..init()),
        BlocProvider(create: (_) => sl<LedgerCubit>()..init()),
        BlocProvider(create: (_) => sl<BalancesCubit>()..load()),
      ],
      child: const _FinanceView(),
    );
  }
}

class _FinanceView extends StatelessWidget {
  const _FinanceView();

  void _openAddChoice(BuildContext context) async {
    final action = await AddChoiceSheet.show(context);
    if (!context.mounted || action == null) return;

    if (action == FinanceChoiceAction.payment) {
      final success = await AddPaymentSheet.show(context);
      if (success == true && context.mounted) {
        context.read<BalancesCubit>().load();
      }
    } else {
      final success = await AddExpensePage.show(context);
      if (success == true && context.mounted) {
        context.read<FinanceOverviewCubit>().setMonth(
              context.read<FinanceOverviewCubit>().selectedMonth,
            );
      }
    }
  }

  void _onMonthChanged(BuildContext context, DateTime newMonth) {
    context.read<FinanceOverviewCubit>().setMonth(newMonth);
    context.read<LedgerCubit>().setMonth(newMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('الحسابات', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 2.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'التقارير والإحصائيات',
            onPressed: () => ReportsPage.show(context),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'finance_fab',
        onPressed: () => _openAddChoice(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'إضافة',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final month = context.read<FinanceOverviewCubit>().selectedMonth;
            context.read<FinanceOverviewCubit>().setMonth(month);
            context.read<LedgerCubit>().setMonth(month);
            context.read<BalancesCubit>().load();
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
                context.read<LedgerCubit>().loadMore();
              }
              return false;
            },
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Month Selector & 3-Cell Summary Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Month Selector Row
                      BlocBuilder<FinanceOverviewCubit, FinanceOverviewState>(
                        builder: (context, state) {
                          final selectedMonth = context.read<FinanceOverviewCubit>().selectedMonth;
                          final monthLabel = DateFormat('MMMM yyyy', 'ar').format(selectedMonth);

                          return Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  tooltip: 'الشهر السابق',
                                  onPressed: () {
                                    final prev = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
                                    _onMonthChanged(context, prev);
                                  },
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      monthLabel,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded),
                                  tooltip: 'الشهر التالي',
                                  onPressed: () {
                                    final next = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
                                    _onMonthChanged(context, next);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 3-Cell Summary Card with skeletonizer loading
                      BlocBuilder<FinanceOverviewCubit, FinanceOverviewState>(
                        builder: (context, state) {
                          if (state is FinanceOverviewLoading) {
                            return Skeletonizer(
                              enabled: true,
                              child: FinanceSummaryCard(
                                summary: FinanceSummary(
                                  revenue: 12500,
                                  expenses: 4200,
                                  net: 8300,
                                  selectedMonth: state.selectedMonth,
                                ),
                              ),
                            );
                          }

                          if (state is FinanceOverviewLoaded) {
                            return FinanceSummaryCard(summary: state.summary);
                          }

                          if (state is FinanceOverviewError) {
                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.errorTint,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Text(
                                state.message,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Members with balances section
              SliverToBoxAdapter(
                child: BlocBuilder<BalancesCubit, BalancesState>(
                  builder: (context, state) {
                    if (state is BalancesLoaded && state.filteredBalances.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.errorTint,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.money_off_rounded,
                                  color: AppColors.error,
                                  size: 18,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    'مشتركون عليهم مستحقات',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorTint,
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text(
                                      '${state.filteredBalances.length}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'إجمالي المتبقي: ${CurrencyFormatter.format(state.totalOutstanding)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              children: [
                                const Divider(height: 1),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 220),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: state.filteredBalances.length,
                                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 48),
                                    itemBuilder: (context, index) {
                                      final balance = state.filteredBalances[index];
                                      return BalanceTile(
                                        balance: balance,
                                        onTap: () async {
                                          final success = await AddPaymentSheet.show(
                                            context,
                                            preselectedMemberId: balance.memberId,
                                          );
                                          if (success == true && context.mounted) {
                                            context.read<BalancesCubit>().load();
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // 3. Segmented Control: الكل · الإيرادات · المصروفات
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: BlocBuilder<LedgerCubit, LedgerState>(
                    builder: (context, state) {
                      final currentFilter = context.read<LedgerCubit>().currentFilter;

                      return SegmentedSelector<LedgerType>(
                        segments: const [
                          SegmentItem(value: LedgerType.all, label: 'الكل'),
                          SegmentItem(value: LedgerType.income, label: 'الإيرادات'),
                          SegmentItem(value: LedgerType.expense, label: 'المصروفات'),
                        ],
                        selectedValue: currentFilter,
                        onSelected: (val) => context.read<LedgerCubit>().setFilter(val),
                      );
                    },
                  ),
                ),
              ),

              // 4. Transaction List grouped by day with sticky day headers & daily totals
              BlocBuilder<LedgerCubit, LedgerState>(
                builder: (context, state) {
                  if (state is LedgerLoading) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Skeletonizer(
                          enabled: true,
                          child: Column(
                            children: List.generate(
                              5,
                              (i) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: TransactionTile(
                                  entry: LedgerEntry(
                                    id: 'temp_$i',
                                    originalId: i,
                                    type: i.isEven ? LedgerType.income : LedgerType.expense,
                                    amount: 250,
                                    date: DateTime.now(),
                                    title: 'معاملة تجريبية سريعة',
                                    subtitle: 'تفاصيل إضافية',
                                    isVoided: false,
                                    voidReason: null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is LedgerEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: EmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'لا توجد معاملات مسجلة',
                          subtitle: 'ابدأ بتسجيل أول دفعة أو مصروف لهذا الشهر',
                          actionLabel: 'تسجيل أول دفعة',
                          onAction: () async {
                            final success = await AddPaymentSheet.show(context);
                            if (success == true && context.mounted) {
                              context.read<BalancesCubit>().load();
                            }
                          },
                        ),
                      ),
                    );
                  }

                  if (state is LedgerError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              state.message,
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton(
                              onPressed: () {
                                final m = context.read<FinanceOverviewCubit>().selectedMonth;
                                context.read<LedgerCubit>().setMonth(m);
                              },
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is LedgerLoaded) {
                    final dayKeys = state.groupedByDay.keys.toList()
                      ..sort((a, b) => b.compareTo(a));

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        AppSpacing.xxxl + AppSpacing.xl, // Space for extended FAB
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == dayKeys.length) {
                              return const PaginatedBottomLoader(isLoading: true);
                            }
                            final dayKey = dayKeys[index];
                            final dayEntries = state.groupedByDay[dayKey] ?? [];
                            final dailyTotal = state.dailyTotals[dayKey] ??
                                DailyTotal(date: dayKey, revenue: 0, expenses: 0, net: 0);

                            return _buildDayGroup(
                              context: context,
                              day: dayKey,
                              entries: dayEntries,
                              dailyTotal: dailyTotal,
                            );
                          },
                          childCount: dayKeys.length + (state.isLoadingMore ? 1 : 0),
                        ),
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildDayGroup({
    required BuildContext context,
    required DateTime day,
    required List<LedgerEntry> entries,
    required DailyTotal dailyTotal,
  }) {
    final now = DateTime.now();
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
    final dayLabel = isToday
        ? 'اليوم - ${DateFormat('d MMMM yyyy', 'ar').format(day)}'
        : DateFormat('EEEE، d MMMM yyyy', 'ar').format(day);

    final netPrefix = dailyTotal.net > 0 ? '+' : '';
    final netColor = dailyTotal.net >= 0 ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Day Header with sticky-style daily summary
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayLabel,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الصافي: ',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$netPrefix${CurrencyFormatter.format(dailyTotal.net)}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: netColor,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Entries in this day
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, idx) {
                final entry = entries[idx];
                return TransactionTile(
                  entry: entry,
                  onTap: () async {
                    if (entry.isVoided) return;
                    final reason = await VoidConfirmationDialog.show(
                      context,
                      entry: entry,
                    );
                    if (reason != null && context.mounted) {
                      if (entry.type == LedgerType.income) {
                        await context.read<LedgerCubit>().voidPayment(
                              entry.originalId,
                              reason: reason.isNotEmpty ? reason : null,
                            );
                        if (context.mounted) {
                          context.read<BalancesCubit>().load();
                        }
                      } else {
                        await context.read<LedgerCubit>().voidExpense(entry.originalId);
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
