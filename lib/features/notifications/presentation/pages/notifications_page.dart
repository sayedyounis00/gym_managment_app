import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../members/domain/entities/member_summary.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/empty_notifications_view.dart';
import '../widgets/notification_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Symbols.arrow_back_rounded),
            tooltip: 'رجوع',
            onPressed: () => context.pop(),
          ),
          title: Text(
            'الإشعارات والتنبيهات',
            style: AppTextStyles.titleLarge,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) {
                final expiringCount =
                    state is NotificationsLoaded ? state.expiringSoon.length : 0;
                final expiredCount =
                    state is NotificationsLoaded ? state.expired.length : 0;

                return TabBar(
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.labelLarge,
                  unselectedLabelStyle: AppTextStyles.bodyMedium,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Symbols.schedule_rounded, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Text('تنتهي قريباً ($expiringCount)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Symbols.timer_off_rounded, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Text('منتهية حديثاً ($expiredCount)'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              } else if (state is NotificationsError) {
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
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          state.message,
                          style: AppTextStyles.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: () =>
                              context.read<NotificationsCubit>().refresh(),
                          icon: const Icon(Symbols.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is NotificationsLoaded) {
                return TabBarView(
                  children: [
                    // Tab 1: Expiring soon
                    _NotificationsTabContent(
                      items: state.expiringSoon,
                      emptyTitle: 'لا توجد اشتراكات تنتهي قريباً',
                      emptySubtitle:
                          'جميع المشتركين لديهم فترات كافية في باقاتهم الحالية',
                      emptyIcon: Symbols.check_circle_rounded,
                      emptyIconColor: AppColors.success,
                      emptyBgColor: AppColors.successTint,
                    ),

                    // Tab 2: Already expired
                    _NotificationsTabContent(
                      items: state.expired,
                      emptyTitle: 'لا توجد اشتراكات منتهية حديثاً',
                      emptySubtitle:
                          'لا توجد اشتراكات انتهت خلال آخر 30 يوماً',
                      emptyIcon: Symbols.verified_rounded,
                      emptyIconColor: AppColors.primary,
                      emptyBgColor: AppColors.primaryLight,
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationsTabContent extends StatelessWidget {
  final List<MemberSummary> items;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final Color emptyIconColor;
  final Color emptyBgColor;

  const _NotificationsTabContent({
    required this.items,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.emptyIconColor,
    required this.emptyBgColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => context.read<NotificationsCubit>().refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: EmptyNotificationsView(
                title: emptyTitle,
                subtitle: emptySubtitle,
                icon: emptyIcon,
                iconColor: emptyIconColor,
                backgroundColor: emptyBgColor,
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => context.read<NotificationsCubit>().refresh(),
          child: isWide
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        mainAxisExtent: 135,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final member = items[index];
                        return NotificationCard(
                          member: member,
                          onTap: () => context.push(
                            AppRoutes.memberDetailsPath(member.id),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final member = items[index];
                    return NotificationCard(
                      member: member,
                      onTap: () => context.push(
                        AppRoutes.memberDetailsPath(member.id),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
