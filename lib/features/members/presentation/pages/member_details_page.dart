import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/utils/currency_formatter.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'package:gym_managment_app/core/utils/responsive_utils.dart';
import 'package:gym_managment_app/core/widgets/app_button.dart';
import 'package:gym_managment_app/core/widgets/confirm_dialog.dart';
import 'package:gym_managment_app/core/widgets/skeletons/skeletons.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/subscription_history_item.dart';

import '../../domain/entities/gender.dart';
import '../cubit/member_details/member_details_cubit.dart';
import '../cubit/member_details/member_details_state.dart';
import '../cubit/member_notes/member_notes_cubit.dart';
import '../cubit/member_notes/member_notes_state.dart';
import '../widgets/bmi_card.dart';
import '../widgets/body_stats_card.dart';
import '../widgets/current_membership_card.dart';
import '../widgets/member_avatar.dart';
import '../widgets/notes_tab.dart';

import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/features/memberships/presentation/cubit/pause/pause_cubit.dart';
import 'package:gym_managment_app/features/memberships/presentation/widgets/renew_bottom_sheet.dart';
import 'package:gym_managment_app/features/memberships/presentation/widgets/pause_bottom_sheet.dart';
import 'package:gym_managment_app/features/finance/presentation/widgets/add_payment_sheet.dart';
import 'package:gym_managment_app/features/finance/presentation/widgets/void_dialog.dart';
import 'package:gym_managment_app/features/finance/domain/entities/ledger_entry.dart';
import 'package:gym_managment_app/features/finance/domain/entities/finance_enums.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/void_payment.dart';

class MemberDetailsPage extends StatefulWidget {
  final int memberId;

  const MemberDetailsPage({super.key, required this.memberId});

  @override
  State<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<MemberDetailsCubit>().load(widget.memberId);
    context.read<MemberNotesCubit>().init(widget.memberId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    // WhatsApp requires international format without leading zeros
    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '2$cleanPhone';
    }
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showAddPaymentDialog(
    int memberId,
    List<SubscriptionHistoryItem> subscriptions,
  ) async {
    final success = await AddPaymentSheet.show(
      context,
      preselectedMemberId: memberId,
    );
    if (success == true && mounted) {
      context.read<MemberDetailsCubit>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الدفعة بنجاح وتحديث الرصيد'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showRenewSheet([String? memberName, int? packageId]) async {
    final state = context.read<MemberDetailsCubit>().state;
    String name = memberName ?? '';
    if (name.isEmpty && state is MemberDetailsLoaded) {
      name = state.data.member.name;
    }
    final renewed = await RenewBottomSheet.show(
      context,
      memberId: widget.memberId,
      memberName: name,
      preselectedPackageId: packageId,
    );
    if (renewed == true && mounted) {
      context.read<MemberDetailsCubit>().load(widget.memberId);
    }
  }

  Future<void> _handlePauseOrResume(dynamic member) async {
    if (member.isSuspended) {
      final confirm = await ConfirmDialog.show(
        context,
        title: 'استئناف اشتراك ${member.name}؟',
        message: 'سيتم استئناف الاشتراك وتمديد تاريخ الانتهاء بمقدار أيام فترة الإيقاف المؤقت.',
        confirmLabel: 'استئناف الاشتراك',
      );
      if (confirm == true && mounted) {
        HapticFeedback.lightImpact();
        final pauseCubit = sl<PauseCubit>();
        final ok = await pauseCubit.resume(
          memberId: widget.memberId,
          resumeDate: DateTime.now(),
        );
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم استئناف اشتراك ${member.name} بنجاح'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<MemberDetailsCubit>().load(widget.memberId);
        }
      }
    } else {
      final paused = await PauseBottomSheet.show(
        context,
        memberId: widget.memberId,
        memberName: member.name,
      );
      if (paused == true && mounted) {
        context.read<MemberDetailsCubit>().load(widget.memberId);
      }
    }
  }

  Future<void> _confirmDelete(String name) async {
    final cubit = context.read<MemberDetailsCubit>();
    final confirm = await ConfirmDialog.show(
      context,
      title: 'حذف المشترك $name؟',
      message: 'سيتم حذف المشترك وجميع بياناته واشتراكاته ومدفوعاته وملاحظاته نهائياً. لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف نهائي',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      HapticFeedback.mediumImpact();
      cubit.delete();
    }
  }

  Future<void> _confirmDeleteSubscription(SubscriptionHistoryItem sub) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'حذف اشتراك ${sub.packageName}؟',
      message: 'هل تريد حذف هذا الاشتراك؟ سيتم حذف بيانات الاشتراك والمدفوعات المرتبطة به في حال تمت إضافته بالخطأ. لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف الاشتراك',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      HapticFeedback.mediumImpact();
      final success = await context.read<MemberDetailsCubit>().deleteSubscription(sub.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الاشتراك بنجاح'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemberDetailsCubit, MemberDetailsState>(
      listener: (context, state) {
        if (state is MemberDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المشترك بنجاح'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop(true);
        } else if (state is MemberDetailsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('تفاصيل المشترك', style: AppTextStyles.titleLarge),
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 2,
          actions: [
            BlocBuilder<MemberDetailsCubit, MemberDetailsState>(
              builder: (context, state) {
                if (state is MemberDetailsLoaded) {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'تعديل البيانات',
                        onPressed: () async {
                          final cubit = context.read<MemberDetailsCubit>();
                          final updated = await context.push(
                            '/members/${widget.memberId}/edit',
                          );
                          if (updated == true && mounted) {
                            cubit.refresh();
                          }
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        tooltip: 'خيارات إضافية',
                        onSelected: (val) {
                          if (val == 'delete') {
                            _confirmDelete(state.data.member.name);
                          } else if (val == 'suspend') {
                            _handlePauseOrResume(state.data.member);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'suspend',
                            child: Row(
                              children: [
                                Icon(
                                  state.data.member.isSuspended
                                      ? Icons.play_circle_outline_rounded
                                      : Icons.pause_circle_outline_rounded,
                                  color: AppColors.paused,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  state.data.member.isSuspended
                                      ? 'استئناف العضوية'
                                      : 'إيقاف مؤقت',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  'حذف المشترك',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<MemberDetailsCubit, MemberDetailsState>(
          builder: (context, state) {
            if (state is MemberDetailsLoading) {
              return const MemberDetailsSkeleton();
            }

            if (state is MemberDetailsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    state.message,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              );
            }

            if (state is MemberDetailsLoaded) {
              final member = state.data.member;
              final status = state.data.status;
              final currentSub = state.data.currentSubscription;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await context.read<MemberDetailsCubit>().refresh();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ResponsiveCenteredContainer(
                    maxWidth: 760,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Profile Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MemberAvatar(
                                    photoPath: member.photoPath,
                                    name: member.name,
                                    size: 80,
                                    enablePreview: true,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                member.name,
                                                style: AppTextStyles.titleLarge
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            StatusChip.memberStatus(status),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              member.phone,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    color: AppColors.textSecondary,
                                                  ),
                                            ),
                                            if (member.gender != null) ...[
                                              const SizedBox(width: AppSpacing.sm),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceVariant,
                                                  borderRadius: BorderRadius.circular(
                                                    AppRadius.full,
                                                  ),
                                                  border: Border.all(
                                                    color: AppColors.border,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      member.gender == Gender.male
                                                          ? Icons.male_rounded
                                                          : Icons.female_rounded,
                                                      size: 13,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      member.gender!.label,
                                                      style: AppTextStyles.labelSmall.copyWith(
                                                        color: AppColors.textSecondary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.md,
                                                  ),
                                              onTap: () =>
                                                  _makeCall(member.phone),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.successTint,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppRadius.md,
                                                      ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.call_rounded,
                                                      size: 16,
                                                      color: AppColors.success,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'اتصال',
                                                      style: AppTextStyles
                                                          .labelMedium
                                                          .copyWith(
                                                            color: AppColors
                                                                .success,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.md,
                                                  ),
                                              onTap: () =>
                                                  _openWhatsApp(member.phone),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFE8F7F0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppRadius.md,
                                                      ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .chat_bubble_outline_rounded,
                                                      size: 16,
                                                      color: Color(0xFF25D366),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'واتساب',
                                                      style: AppTextStyles
                                                          .labelMedium
                                                          .copyWith(
                                                            color: const Color(
                                                              0xFF1EBE5D,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
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

                        // Action Row
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'تجديد',
                                variant: AppButtonVariant.primary,
                                leadingIcon: Icons.autorenew_rounded,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                onPressed: () => _showRenewSheet(
                                  member.name,
                                  currentSub?.id,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: AppButton(
                                label: member.isSuspended
                                    ? 'استئناف'
                                    : 'إيقاف مؤقت',
                                variant: AppButtonVariant.secondary,
                                leadingIcon: member.isSuspended
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                isLoading: state.isActionLoading,
                                onPressed: () => _handlePauseOrResume(member),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: AppButton(
                                label: 'إضافة دفعة',
                                variant: AppButtonVariant.secondary,
                                leadingIcon: Icons.payment_rounded,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                onPressed: () => _showAddPaymentDialog(
                                  member.id,
                                  state.data.subscriptions,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Body stats card
                        BodyStatsCard(
                          age: member.age,
                          weightKg: member.weightKg,
                          heightCm: member.heightCm,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // BMI card
                        BmiCard(bmi: member.bmi),
                        const SizedBox(height: AppSpacing.md),

                        // Current membership card
                        CurrentMembershipCard(
                          subscription: currentSub,
                          status: status,
                          onRenew: () =>
                              _showRenewSheet(member.name, currentSub?.id),
                          onDelete: currentSub != null
                              ? () => _confirmDeleteSubscription(currentSub)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: TabBar(
                            controller: _tabController,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ),
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorColor: AppColors.primary,
                            indicatorWeight: 3,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelStyle: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: AppTextStyles.labelMedium
                                .copyWith(fontWeight: FontWeight.w500),
                            tabs: const [
                              Tab(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('الاشتراكات', maxLines: 1),
                                ),
                              ),
                              Tab(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('المدفوعات', maxLines: 1),
                                ),
                              ),
                              Tab(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('الملاحظات', maxLines: 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Tab contents
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            final index = _tabController.index;
                            if (index == 0) {
                              return _buildSubscriptionsTab(
                                state.data.subscriptions,
                              );
                            } else if (index == 1) {
                              return _buildPaymentsTab(
                                state.data.payments,
                                state.data.subscriptions,
                                state.data.member.id,
                              );
                            } else {
                              return _buildNotesTab();
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
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
    );
  }

  Widget _buildSubscriptionsTab(List<SubscriptionHistoryItem> subscriptions) {
    if (subscriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        alignment: Alignment.center,
        child: Text(
          'لا يوجد سجل اشتراكات سابقة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subscriptions.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs + 2,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Text(sub.packageName, style: AppTextStyles.titleMedium),
                        if (sub.paymentMethod != null)
                          StatusChip.paymentMethod(sub.paymentMethod!),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${AppDateUtils.formatShortDate(sub.startDate)}  ←  ${AppDateUtils.formatShortDate(sub.endDate)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'السعر: ${CurrencyFormatter.format(sub.price)}  ·  المدفوع: ${CurrencyFormatter.format(sub.paidAmount)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: sub.remainingAmount > 0
                            ? AppColors.error
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip.memberStatus(sub.status),
                  const SizedBox(height: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    tooltip: 'حذف الاشتراك',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDeleteSubscription(sub),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab(
    List<dynamic> payments,
    List<SubscriptionHistoryItem> subscriptions,
    int memberId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('سجل المدفوعات', style: AppTextStyles.titleMedium),
            AppButton(
              label: 'إضافة دفعة',
              variant: AppButtonVariant.primary,
              leadingIcon: Icons.add_rounded,
              onPressed: () => _showAddPaymentDialog(
                memberId,
                subscriptions,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (payments.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 40,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'لا توجد مدفوعات مسجلة حتى الآن',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final dateFormat = DateFormat('d MMMM yyyy - hh:mm a', 'ar');

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.successTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payment_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CurrencyFormatter.format(payment.amount),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: payment.isVoided
                                  ? AppColors.textDisabled
                                  : AppColors.success,
                              fontWeight: FontWeight.w700,
                              decoration: payment.isVoided
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            dateFormat.format(payment.paidAt),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (payment.notes != null &&
                              payment.notes!.isNotEmpty)
                            Text(
                              payment.notes!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (payment.isVoided)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.errorTint,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          'ملغاة',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else ...[
                      StatusChip.paymentMethod(payment.paymentMethod),
                      IconButton(
                        icon: const Icon(Icons.undo_rounded, size: 18, color: AppColors.textSecondary),
                        tooltip: 'إلغاء الدفعة',
                        onPressed: () async {
                          final reason = await VoidConfirmationDialog.show(
                            context,
                            entry: LedgerEntry(
                              id: 'payment_${payment.id}',
                              originalId: payment.id,
                              type: LedgerType.income,
                              amount: payment.amount,
                              date: payment.paidAt,
                              title: 'دفعة بقيمة ${CurrencyFormatter.format(payment.amount)}',
                              isVoided: false,
                            ),
                          );
                          if (reason != null && context.mounted) {
                            final voidResult = await sl<VoidPayment>()(payment.id, reason: reason.isNotEmpty ? reason : null);
                            if (context.mounted) {
                              voidResult.fold(
                                (fail) => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(fail.message), backgroundColor: AppColors.error),
                                ),
                                (_) {
                                  context.read<MemberDetailsCubit>().refresh();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم إلغاء الدفعة بنجاح'), backgroundColor: AppColors.success),
                                  );
                                },
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNotesTab() {
    return BlocBuilder<MemberNotesCubit, MemberNotesState>(
      builder: (context, state) {
        if (state is MemberNotesLoading) {
          return const NotesSkeleton();
        }
        if (state is MemberNotesLoaded) {
          return NotesTab(
            notes: state.notes,
            onAddNote: (text) =>
                context.read<MemberNotesCubit>().submitAddNote(text),
            onUpdateNote: (id, text) =>
                context.read<MemberNotesCubit>().submitUpdateNote(id, text),
            onDeleteNote: (id) =>
                context.read<MemberNotesCubit>().submitDeleteNote(id),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
