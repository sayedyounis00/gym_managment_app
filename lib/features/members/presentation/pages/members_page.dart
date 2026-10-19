import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/utils/responsive_utils.dart';
import 'package:gym_managment_app/core/widgets/empty_state.dart';
import 'package:gym_managment_app/core/widgets/paginated_bottom_loader.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/core/widgets/skeletons/members_list_skeleton.dart';
import '../cubit/members_list/members_list_cubit.dart';
import '../cubit/members_list/members_list_state.dart';
import '../widgets/member_card.dart';
import '../widgets/member_filter_bar.dart';
import '../widgets/member_search_bar.dart';
import '../../../settings/presentation/pages/export_sheet.dart';

class MembersPage extends StatefulWidget {
  final String? initialStatusFilter;

  const MembersPage({super.key, this.initialStatusFilter});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    MemberStatusType? filter;
    if (widget.initialStatusFilter != null) {
      filter = MemberStatusType.values.where(
        (e) => e.name.toLowerCase() == widget.initialStatusFilter!.toLowerCase(),
      ).firstOrNull;
    }
    context.read<MembersListCubit>().init(initialFilter: filter);
  }

  @override
  void didUpdateWidget(covariant MembersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatusFilter != widget.initialStatusFilter) {
      MemberStatusType? filter;
      if (widget.initialStatusFilter != null) {
        filter = MemberStatusType.values.where(
          (e) => e.name.toLowerCase() == widget.initialStatusFilter!.toLowerCase(),
        ).firstOrNull;
      }
      context.read<MembersListCubit>().setFilter(filter);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      context.read<MembersListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'تصدير المشتركين',
            onPressed: () {
              final state = context.read<MembersListCubit>().state;
              final currentFilter = state is MembersListLoaded ? state.filter : null;
              ExportSheet.show(context, initialStatusFilter: currentFilter);
            },
          ),
        ],
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
                        message: 'ابدأ بإضافة أول مشترك في الجيم لمتابعة الاشتراكات والمدفوعات.',
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
                                    ? CustomScrollView(
                                        controller: _scrollController,
                                        slivers: [
                                          SliverPadding(
                                            padding: const EdgeInsets.all(AppSpacing.md),
                                            sliver: SliverGrid(
                                              gridDelegate:
                                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                                maxCrossAxisExtent: 460,
                                                mainAxisExtent: 88,
                                                crossAxisSpacing: AppSpacing.md,
                                                mainAxisSpacing: AppSpacing.md,
                                              ),
                                              delegate: SliverChildBuilderDelegate(
                                                (context, index) {
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
                                                childCount: state.members.length,
                                              ),
                                            ),
                                          ),
                                          if (state.isLoadingMore)
                                            const SliverToBoxAdapter(
                                              child: PaginatedBottomLoader(isLoading: true),
                                            ),
                                          const SliverToBoxAdapter(
                                            child: SizedBox(height: 88),
                                          ),
                                        ],
                                      )
                                    : ListView.separated(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.only(
                                          bottom: 88, // Space for FAB
                                        ),
                                        itemCount: state.members.length + (state.isLoadingMore ? 1 : 0),
                                        separatorBuilder: (context, index) {
                                          if (index >= state.members.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return const Divider(
                                            height: 1,
                                            indent: 68,
                                            color: AppColors.border,
                                          );
                                        },
                                        itemBuilder: (context, index) {
                                          if (index == state.members.length) {
                                            return const PaginatedBottomLoader(isLoading: true);
                                          }
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
