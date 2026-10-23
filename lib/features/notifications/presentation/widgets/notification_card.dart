import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../members/domain/entities/member_summary.dart';
import '../../../members/presentation/widgets/member_avatar.dart';
import '../../../memberships/presentation/widgets/renew_bottom_sheet.dart';

class NotificationCard extends StatelessWidget {
  final MemberSummary member;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.member,
    required this.onTap,
  });

  bool get _isExpired => member.status == MemberStatusType.expired;

  String _formatStatusText() {
    final days = member.daysLeft;
    if (_isExpired) {
      if (days == null || days == 0) return 'انتهى اليوم';
      if (days == -1) return 'انتهى أمس';
      return 'منتهي منذ ${days.abs()} يوم';
    } else {
      if (days == null || days == 0) return 'ينتهي اليوم';
      if (days == 1) return 'ينتهي غداً';
      return 'متبقي $days أيام';
    }
  }

  Future<void> _makeCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر الاتصال برقم $phone'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '2$cleanPhone';
    }
    final appUri = Uri.parse('whatsapp://send?phone=$cleanPhone');
    final webUri = Uri.parse('https://wa.me/$cleanPhone');

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر فتح واتساب للرقم $phone'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeBg = _isExpired ? AppColors.errorTint : AppColors.warningTint;
    final badgeColor = _isExpired ? AppColors.error : AppColors.warning;
    final badgeIcon =
        _isExpired ? Symbols.timer_off_rounded : Symbols.schedule_rounded;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _isExpired
              ? AppColors.error.withValues(alpha: 0.25)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(27, 33, 48, 0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Avatar + Name & Package + Expiration badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MemberAvatar(
                      photoPath: member.photoPath,
                      name: member.name,
                      size: 44,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Symbols.fitness_center_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  member.packageName ?? 'بدون باقة',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            badgeIcon,
                            size: 14,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatStatusText(),
                            style: AppTextStyles.caption.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),

                // Info & Action Row
                Row(
                  children: [
                    // Date display
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Symbols.event_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              member.subscriptionEndDate != null
                                  ? AppDateUtils.formatShortDate(
                                      member.subscriptionEndDate!)
                                  : 'غير محدد',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions: Call, WhatsApp, Renew
                    IconButton(
                      icon: const Icon(Symbols.call_rounded),
                      iconSize: 20,
                      color: AppColors.primary,
                      tooltip: 'اتصال هاتفياً',
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => _makeCall(context, member.phone),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.chat_rounded),
                      iconSize: 20,
                      color: AppColors.success,
                      tooltip: 'مراسلة عبر واتساب',
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => _openWhatsApp(context, member.phone),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Symbols.autorenew_rounded, size: 16),
                      label: Text(
                        'تجديد',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        RenewBottomSheet.show(
                          context,
                          memberId: member.id,
                          memberName: member.name,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
