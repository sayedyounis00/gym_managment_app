import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/skeletons/dashboard_skeleton.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/expiring_list.dart';
import '../widgets/finance_summary.dart';
import '../widgets/stat_card.dart';
import '../widgets/backup_reminder_banner.dart';
import 'package:gym_managment_app/features/memberships/presentation/widgets/renew_bottom_sheet.dart';
import 'package:gym_managment_app/features/finance/presentation/widgets/add_payment_sheet.dart';
import 'package:gym_managment_app/features/finance/presentation/pages/add_expense_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _expiringKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToExpiring() {
    final context = _expiringKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'أهلاً بك';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'لوحة التحكم',
              style: AppTextStyles.titleLarge,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.settings_rounded),
            tooltip: 'الإعدادات والنسخ الاحتياطي',
            onPressed: () => context.push(AppRoutes.settings),
          ),
          BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              final expiringCount = state is DashboardLoaded
                  ? state.summary.expiringSoon.length
                  : 0;

              return IconButton(
                icon: expiringCount > 0
                    ? Badge.count(
                        count: expiringCount,
                        child: const Icon(Symbols.notifications_rounded),
                      )
                    : const Icon(Symbols.notifications_rounded),
                tooltip: 'الإشعارات والتنبيهات',
                onPressed: () {
                  if (state is DashboardLoaded &&
                      state.summary.expiringSoon.isNotEmpty) {
                    _scrollToExpiring();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لا توجد إشعارات جديدة حالياً'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const DashboardSkeleton();
            } else if (state is DashboardError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Symbols.error_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'تعذر تحميل البيانات',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        state.message,
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'إعادة المحاولة',
                        leadingIcon: Symbols.refresh_rounded,
                        onPressed: () =>
                            context.read<DashboardCubit>().loadSummary(),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is DashboardLoaded) {
              final summary = state.summary;

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () => context.read<DashboardCubit>().refresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isDesktop = width >= ResponsiveBreakpoints.medium;
                    final isTablet = width >= ResponsiveBreakpoints.compact &&
                        width < ResponsiveBreakpoints.medium;
                    final isSmallPhone = width < 360;

                    final statCrossAxisCount = (isDesktop || isTablet) ? 4 : 2;
                    final statAspectRatio = isDesktop
                        ? 1.45
                        : (isTablet ? 1.4 : (isSmallPhone ? 1.15 : 1.3));

                    final statCards = [
                      StatCard(
                        title: 'المشتركين النشطين',
                        value: '${summary.activeMembersCount}',
                        icon: Symbols.groups_rounded,
                        accentColor: AppColors.success,
                        subtitle: 'اشتراك سارٍ',
                        onTap: () =>
                            context.go(AppRoutes.membersWithStatus('active')),
                      ),
                      StatCard(
                        title: 'ينتهي قريباً',
                        value: '${summary.expiringSoon.length}',
                        icon: Symbols.schedule_rounded,
                        accentColor: AppColors.warning,
                        subtitle: 'خلال 7 أيام',
                        onTap: _scrollToExpiring,
                      ),
                      StatCard(
                        title: 'مشتركين جدد',
                        value: '${summary.newSubscriptionsThisMonth}',
                        icon: Symbols.person_add_rounded,
                        accentColor: AppColors.info,
                        subtitle: 'هذا الشهر',
                        onTap: () => context.go(AppRoutes.members),
                      ),
                      StatCard(
                        title: 'صافي الأرباح',
                        value: CurrencyFormatter.formatCompact(summary.netProfit),
                        icon: summary.netProfit >= 0
                            ? Symbols.trending_up_rounded
                            : Symbols.trending_down_rounded,
                        accentColor: summary.netProfit >= 0
                            ? AppColors.primary
                            : AppColors.error,
                        subtitle: 'الإيرادات - المصروفات',
                        onTap: () => context.go(AppRoutes.finance),
                      ),
                    ];

                    final financeWidget = FinanceSummaryCard(
                      revenue: summary.monthRevenue,
                      expenses: summary.monthExpenses,
                      todayRevenue: summary.todayRevenue,
                      onTap: () => context.go(AppRoutes.finance),
                    );

                    final expiringWidget = Container(
                      key: _expiringKey,
                      child: ExpiringListSection(
                        expiringSoon: summary.expiringSoon,
                        onViewAllTap: () {
                          context.go(AppRoutes.membersExpiringSoon());
                        },
                        onMemberTap: (item) {
                          context.go(AppRoutes.memberDetailsPath(item.memberId));
                        },
                        onRenewTap: (item) async {
                          final renewed = await RenewBottomSheet.show(
                            context,
                            memberId: item.memberId,
                            memberName: item.memberName,
                          );
                          if (renewed == true && context.mounted) {
                            context.read<DashboardCubit>().refresh();
                          }
                        },
                      ),
                    );

                    return SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ResponsiveCenteredContainer(
                        padding: context.responsivePagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const BackupReminderBanner(),
                            // Date Banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm + 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Symbols.calendar_today_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    AppDateUtils.formatGreetingDate(
                                        DateTime.now()),
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Expiry Alert Banner (if any memberships expire soon)
                            if (summary.expiringSoon.isNotEmpty) ...[
                              InkWell(
                                onTap: _scrollToExpiring,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningTint,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: AppColors.warning
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Symbols.warning_rounded,
                                        color: AppColors.warning,
                                        size: 24,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          'يوجد ${summary.expiringSoon.length} اشتراكات تنتهي قريباً — اضغط للعرض',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            color: const Color(0xFF8A5800),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Symbols.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.warning,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],

                            // Quick Actions Row
                            _buildQuickActions(context),
                            const SizedBox(height: AppSpacing.lg),

                            // Responsive Stat Cards Grid
                            _buildStatCardsLayout(
                              statCards,
                              statCrossAxisCount,
                              statAspectRatio,
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Main Dashboard Content
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: financeWidget,
                                  ),
                                  const SizedBox(width: AppSpacing.xl),
                                  Expanded(
                                    flex: 5,
                                    child: expiringWidget,
                                  ),
                                ],
                              )
                            else ...[
                              financeWidget,
                              const SizedBox(height: AppSpacing.xl),
                              expiringWidget,
                            ],
                            const SizedBox(height: AppSpacing.xxxl),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildStatCardsLayout(
    List<Widget> cards,
    int crossAxisCount,
    double aspectRatio,
  ) {
    if (crossAxisCount == 4) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: cards[i],
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: cards[0],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: cards[1],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: cards[2],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: cards[3],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (
        icon: Symbols.person_add_rounded,
        label: 'إضافة مشترك',
        route: AppRoutes.members,
      ),
      (
        icon: Symbols.card_membership_rounded,
        label: 'تجديد باقة',
        route: AppRoutes.memberships,
      ),
      (
        icon: Symbols.payments_rounded,
        label: 'تسجيل دفعة',
        route: AppRoutes.finance,
      ),
      (
        icon: Symbols.receipt_long_rounded,
        label: 'مصروف جديد',
        route: AppRoutes.finance,
      ),
    ];

    return Row(
      children: actions.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (item.label == 'تسجيل دفعة') {
                    final success = await AddPaymentSheet.show(context);
                    if (success == true && context.mounted) {
                      context.read<DashboardCubit>().refresh();
                    }
                  } else if (item.label == 'مصروف جديد') {
                    final success = await AddExpensePage.show(context);
                    if (success == true && context.mounted) {
                      context.read<DashboardCubit>().refresh();
                    }
                  } else {
                    context.go(item.route);
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Ink(
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 22, color: AppColors.secondary),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.label,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 11,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
