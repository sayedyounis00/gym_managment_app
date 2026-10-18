import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/utils/responsive_utils.dart';
import 'package:gym_managment_app/core/widgets/empty_state.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/core/widgets/skeletons/members_list_skeleton.dart';
import '../cubit/members_list/members_list_cubit.dart';
import '../cubit/members_list/members_list_state.dart';
import '../widgets/member_card.dart';
import '../widgets/member_filter_bar.dart';
import '../widgets/member_search_bar.dart';

class MembersPage extends StatefulWidget {
  final String? initialStatusFilter;

  const MembersPage({super.key, this.initialStatusFilter});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  @override
  void initState() {
    super.initState();
    MemberStatusType? filter;
    if (widget.initialStatusFilter != null) {
      filter = MemberStatusType.values.where(
        (e) => e.name.toLowerCase() == widget.initialStatusFilter!.toLowerCase(),
      ).firstOrNull;
    }
    context.read<MembersListCubit>().init(initialFilter: filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'المشتركين',
          style: AppTextStyles.titleLarge,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_member_fab',
        onPressed: () => context.push('/members/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          'إضافة مشترك',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.onPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and filter headers
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: MemberSearchBar(
                      onChanged: (query) {
                        context.read<MembersListCubit>().search(query);
                      },
                      onClear: () {
                        context.read<MembersListCubit>().search('');
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<MembersListCubit, MembersListState>(
                    buildWhen: (prev, curr) =>
                        curr is MembersListLoaded || curr is MembersListLoading,
                    builder: (context, state) {
                      final currentFilter =
                          state is MembersListLoaded ? state.filter : null;
                      return MemberFilterBar(
                        selectedFilter: currentFilter,
                        onFilterSelected: (filter) {
                          context.read<MembersListCubit>().setFilter(filter);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content list
            Expanded(
              child: BlocBuilder<MembersListCubit, MembersListState>(
                builder: (context, state) {
                  if (state is MembersListLoading) {
                    return const MembersListSkeleton();
                  }

                  if (state is MembersListError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          state.message,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (state is MembersListLoaded) {
                    if (state.members.isEmpty) {
                      if (state.query.isNotEmpty || state.filter != null) {
                        return EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'لا توجد نتائج مطابقة',
                          message: 'لم يتم العثور على أي مشترك مطابق لمعايير البحث الحالية.',
                          actionLabel: 'مسح التصفية',
                          onAction: () {
                            context.read<MembersListCubit>().search('');
                            context.read<MembersListCubit>().setFilter(null);
                          },
                        );
                      }
                      return EmptyState(
                        icon: Icons.group_add_rounded,
                        title: 'لا يوجد مشتركين بعد',
                        message: 'ابدأ بإضافة أول مشترك في الجيم لمتابعة الاشتراكات والحضور.',
                        actionLabel: 'إضافة أول مشترك',
                        onAction: () => context.push('/members/new'),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        context.read<MembersListCubit>().refresh();
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isLargeScreen = constraints.maxWidth >= ResponsiveBreakpoints.compact;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sticky member count header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Text(
                                  '${state.totalCount} مشترك',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: isLargeScreen
                                    ? GridView.builder(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 460,
                                          mainAxisExtent: 88,
                                          crossAxisSpacing: AppSpacing.md,
                                          mainAxisSpacing: AppSpacing.md,
                                        ),
                                        itemCount: state.members.length,
                                        itemBuilder: (context, index) {
                                          final member = state.members[index];
                                          return Container(
                                            key: ValueKey(member.id),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                AppRadius.md,
                                              ),
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: MemberCard(
                                              member: member,
                                              onTap: () => context.push('/members/${member.id}'),
                                            ),
                                          );
                                        },
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.only(
                                          bottom: 88, // Space for FAB
                                        ),
                                        itemCount: state.members.length,
                                        separatorBuilder: (context, index) => const Divider(
                                          height: 1,
                                          indent: 68,
                                          color: AppColors.border,
                                        ),
                                        itemBuilder: (context, index) {
                                          final member = state.members[index];
                                          return MemberCard(
                                            key: ValueKey(member.id),
                                            member: member,
                                            onTap: () => context.push('/members/${member.id}'),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
