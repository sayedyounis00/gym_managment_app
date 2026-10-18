import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/status_chip.dart';
import '../../../../features/members/domain/entities/subscription_history_item.dart';
import '../../../../features/members/presentation/widgets/body_stats_card.dart';
import '../../../../features/members/presentation/widgets/current_membership_card.dart';
import 'fake_data.dart';
import 'liquid_glass_effect.dart';
import 'liquid_skeleton.dart';

/// Full member details screen skeleton built using real widgets and fake data.
/// - Header avatar 80dp
/// - Action row of 3 buttons (Call, WhatsApp, Edit)
/// - Current membership card with progress bar
/// - Body stats card (age, weight, height)
class MemberDetailsSkeleton extends StatelessWidget {
  const MemberDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final fakeMember = FakeData.member();
    final fakeSubscription = SubscriptionHistoryItem(
      id: 1,
      memberId: fakeMember.id,
      packageName: 'باقة اللياقة والقوة الشاملة',
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 23)),
      price: 650.0,
      paidAmount: 650.0,
      status: MemberStatusType.active,
    );

    return LiquidSkeleton(
      enabled: true,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ResponsiveCenteredContainer(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header profile card with 80dp avatar
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: LiquidGlassDecoration.card(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Bone.circle(size: 80),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      fakeMember.name,
                                      style: AppTextStyles.titleLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  StatusChip.memberStatus(fakeMember.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fakeMember.phone,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // Action row of 3 buttons
                              Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.call_rounded,
                                    label: 'اتصال',
                                    color: AppColors.success,
                                    tint: AppColors.successTint,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _buildActionButton(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    label: 'واتساب',
                                    color: AppColors.info,
                                    tint: AppColors.infoTint,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _buildActionButton(
                                    icon: Icons.edit_rounded,
                                    label: 'تعديل',
                                    color: AppColors.secondary,
                                    tint: AppColors.surfaceVariant,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Active Membership Card with Progress Bar
              CurrentMembershipCard(
                subscription: fakeSubscription,
                status: MemberStatusType.active,
                onRenew: () {},
              ),
              const SizedBox(height: AppSpacing.md),

              // Body Stats Card (Age, Weight, Height)
              const BodyStatsCard(age: 26, weightKg: 82.5, heightCm: 178.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
