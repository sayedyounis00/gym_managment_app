import 'package:flutter/material.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';
import 'package:gym_managment_app/features/members/presentation/widgets/member_card.dart';

import 'fake_data.dart';
import 'liquid_skeleton.dart';

/// Single member card skeleton built from real [MemberCard] with fake data.
/// Matches design system Section 6.4:
/// - Avatar 48dp
/// - Name (titleMedium) and status chip
/// - Phone and package name (bodyMedium)
/// - Expiry and days left line
class MemberTileSkeleton extends StatelessWidget {
  final MemberSummary? member;

  const MemberTileSkeleton({super.key, this.member});

  @override
  Widget build(BuildContext context) {
    return LiquidSkeleton(
      enabled: true,
      child: MemberCard(member: member ?? FakeData.member(), onTap: () {}),
    );
  }
}

/// Member list skeleton matching [MembersPage] content list.
class MemberListSkeleton extends StatelessWidget {
  final int count;

  const MemberListSkeleton({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    final items = FakeData.members(count);
    return LiquidSkeleton(
      enabled: true,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) =>
            MemberCard(member: items[index], onTap: () {}),
      ),
    );
  }
}
