import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../../../features/dashboard/presentation/widgets/stat_card.dart';
import 'liquid_skeleton.dart';

/// Single stat card skeleton wrapping real [StatCard] with liquid glass shimmer.
class StatCardSkeleton extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;

  const StatCardSkeleton({
    super.key,
    this.title = 'المشتركين النشطين',
    this.value = '142',
    this.icon = Icons.groups_rounded,
    this.accentColor = AppColors.success,
    this.subtitle = 'اشتراك سارٍ',
  });

  @override
  Widget build(BuildContext context) {
    return LiquidSkeleton(
      enabled: true,
      child: StatCard(
        title: title,
        value: value,
        icon: icon,
        accentColor: accentColor,
        subtitle: subtitle,
      ),
    );
  }
}

/// Responsive 2x2 or 4-column Stat cards grid skeleton for the dashboard.
class StatCardGridSkeleton extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;

  const StatCardGridSkeleton({
    super.key,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidSkeleton(
      enabled: true,
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        children: const [
          StatCardSkeleton(
            title: 'المشتركين النشطين',
            value: '142',
            icon: Icons.groups_rounded,
            accentColor: AppColors.success,
            subtitle: 'اشتراك سارٍ',
          ),
          StatCardSkeleton(
            title: 'ينتهي قريباً',
            value: '7',
            icon: Icons.schedule_rounded,
            accentColor: AppColors.warning,
            subtitle: 'خلال 7 أيام',
          ),
          StatCardSkeleton(
            title: 'مشتركين جدد',
            value: '28',
            icon: Icons.person_add_alt_1_rounded,
            accentColor: AppColors.info,
            subtitle: 'هذا الشهر',
          ),
          StatCardSkeleton(
            title: 'صافي الأرباح',
            value: '18,450',
            icon: Icons.trending_up_rounded,
            accentColor: AppColors.primary,
            subtitle: 'الإيرادات - المصروفات',
          ),
        ],
      ),
    );
  }
}
