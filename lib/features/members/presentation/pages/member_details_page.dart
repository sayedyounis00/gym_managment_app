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
import 'package:gym_managment_app/core/widgets/payment_method_chips.dart';
import 'package:gym_managment_app/core/widgets/skeletons/skeletons.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/subscription_history_item.dart';

import '../cubit/member_details/member_details_cubit.dart';
import '../cubit/member_details/member_details_state.dart';
import '../cubit/member_notes/member_notes_cubit.dart';
import '../cubit/member_notes/member_notes_state.dart';
import '../widgets/body_stats_card.dart';
import '../widgets/current_membership_card.dart';
import '../widgets/member_avatar.dart';
import '../widgets/notes_tab.dart';

import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/features/memberships/presentation/cubit/pause/pause_cubit.dart';
import 'package:gym_managment_app/features/memberships/presentation/widgets/renew_bottom_sheet.dart';
import 'package:gym_managment_app/features/memberships/presentation/widgets/pause_bottom_sheet.dart';

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
    final unpaidSubscriptions =
        subscriptions.where((s) => s.remainingAmount > 0).toList();

    int? selectedSubscriptionId =
        unpaidSubscriptions.isNotEmpty ? unpaidSubscriptions.first.id : null;

    final amountController = TextEditingController(
      text: selectedSubscriptionId != null
          ? unpaidSubscriptions.first.remainingAmount.toStringAsFixed(0)
          : '',
    );
    final notesController = TextEditingController();

    DateTime selectedMonthDate = DateTime.now();
    String paymentMethod = 'cash';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final now = DateTime.now();
            final months = List.generate(12, (i) {
              return DateTime(now.year, now.month - 6 + i, 1);
            });

            final selectedSub = subscriptions
                .where((s) => s.id == selectedSubscriptionId)
                .firstOrNull;

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('إضافة دفعة جديدة', style: AppTextStyles.titleMedium),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Unpaid subscription connection
                    Text(
                      'ربط باشتراك غير مسدد',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: selectedSubscriptionId,
                          dropdownColor: AppColors.surface,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('دفعة عامة (بدون ربط باشتراك)'),
                            ),
                            ...unpaidSubscriptions.map((sub) {
                              return DropdownMenuItem<int?>(
                                value: sub.id,
                                child: Text(
                                  '${sub.packageName} - متبقي دين: ${CurrencyFormatter.format(sub.remainingAmount)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              selectedSubscriptionId = val;
                              final sub = subscriptions
                                  .where((s) => s.id == val)
                                  .firstOrNull;
                              if (sub != null && sub.remainingAmount > 0) {
                                amountController.text =
                                    sub.remainingAmount.toStringAsFixed(0);
                                selectedMonthDate = sub.startDate;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    if (selectedSub != null && selectedSub.remainingAmount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'إجمالي سعر الباقة: ${CurrencyFormatter.format(selectedSub.price)} · المدفوع: ${CurrencyFormatter.format(selectedSub.paidAmount)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // 2. Month selection
                    Text(
                      'عن شهر',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DateTime>(
                          isExpanded: true,
                          value: months.firstWhere(
                            (m) =>
                                m.year == selectedMonthDate.year &&
                                m.month == selectedMonthDate.month,
                            orElse: () => months[6],
                          ),
                          dropdownColor: AppColors.surface,
                          items: months.map((m) {
                            final label =
                                DateFormat('MMMM yyyy', 'ar').format(m);
                            return DropdownMenuItem<DateTime>(
                              value: m,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedMonthDate = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Amount of money
                    Text(
                      'المبلغ المدفوع (ج.م)',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.payments_rounded, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 4. Payment method chips
                    Text(
                      'طريقة الدفع',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PaymentMethodChips(
                      selectedMethod: paymentMethod,
                      onSelected: (method) {
                        setDialogState(() {
                          paymentMethod = method;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 5. Notes (optional)
                    Text(
                      'ملاحظات إضافية (اختياري)',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        hintText: 'مثال: سداد باقي اشتراك...',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى إدخال مبلغ صحيح أكبر من صفر'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final monthLabel =
                        DateFormat('MMMM yyyy', 'ar').format(selectedMonthDate);
                    final extraNotes = notesController.text.trim();
                    final fullNotes =
                        'عن شهر $monthLabel${extraNotes.isNotEmpty ? ' - $extraNotes' : ''}';

                    final success = await context
                        .read<MemberDetailsCubit>()
                        .recordPayment(
                          amount: amount,
                          paymentMethod: paymentMethod,
                          paidAt: DateTime.now(),
                          subscriptionId: selectedSubscriptionId,
                          notes: fullNotes,
                        );

                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop(success);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('تأكيد الدفعة'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    notesController.dispose();

    if (result == true && mounted) {
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

  Future<void> _confirmDelete(String name, bool hasPayments) async {
    if (hasPayments) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            'تعذر حذف المشترك',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.error),
          ),
          content: Text(
            'لا يمكن حذف المشترك $name لوجود سجلات مالية مسجلة له لحماية الحسابات. يمكنك إيقاف العضوية مؤقتاً بدلاً من ذلك.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<MemberDetailsCubit>().toggleSuspension();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paused,
                foregroundColor: Colors.white,
              ),
              child: const Text('إيقاف المشترك مؤقتاً'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await ConfirmDialog.show(
      context,
      title: 'حذف المشترك $name؟',
      message: 'سيتم حذف المشترك وجميع سجلات الحضور والملاحظات الخاصة به نهائياً. لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف نهائي',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      HapticFeedback.mediumImpact();
      context.read<MemberDetailsCubit>().delete();
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
                            _confirmDelete(
                              state.data.member.name,
                              state.data.hasPayments,
                            );
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
                                        Text(
                                          member.phone,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
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

                        // Current membership card
                        CurrentMembershipCard(
                          subscription: currentSub,
                          status: status,
                          onRenew: () =>
                              _showRenewSheet(member.name, currentSub?.id),
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
              StatusChip.memberStatus(sub.status),
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
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
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
                    StatusChip.paymentMethod(payment.paymentMethod),
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
