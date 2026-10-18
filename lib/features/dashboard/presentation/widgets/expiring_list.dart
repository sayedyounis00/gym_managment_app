import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/expiring_subscription.dart';

class ExpiringListSection extends StatelessWidget {
  final List<ExpiringSubscription> expiringSoon;
  final ValueChanged<ExpiringSubscription>? onMemberTap;
  final ValueChanged<ExpiringSubscription>? onRenewTap;

  const ExpiringListSection({
    super.key,
    required this.expiringSoon,
    this.onMemberTap,
    this.onRenewTap,
  });

  Future<void> _makeCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الاتصال برقم $phone')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
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
            SnackBar(content: Text('تعذر فتح واتساب للرقم $phone')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.warningTint,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Symbols.schedule_rounded,
                      size: 20,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'تنتهي قريباً (خلال 7 أيام)',
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: expiringSoon.isEmpty
                    ? AppColors.successTint
                    : AppColors.warningTint,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${expiringSoon.length} مشترك',
                style: AppTextStyles.labelMedium.copyWith(
                  color: expiringSoon.isEmpty
                      ? AppColors.success
                      : AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (expiringSoon.isEmpty)
          _buildEmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < expiringSoon.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm + 2),
                    _buildExpiringItem(context, expiringSoon[i], isNarrow: isNarrow),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.successTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.check_circle_rounded,
              color: AppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'جميع الاشتراكات سارية',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'لا توجد اشتراكات تنتهي خلال الـ 7 أيام القادمة.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringItem(
    BuildContext context,
    ExpiringSubscription item, {
    required bool isNarrow,
  }) {
    final (badgeText, badgeBg, badgeTextColor) =
        _getDaysLeftBadge(item.daysLeft);

    final callButton = IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Symbols.call_rounded, size: 20, color: AppColors.info),
      tooltip: 'اتصال بالمشترك',
      onPressed: () => _makeCall(context, item.phone),
    );

        final whatsAppButton = IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Symbols.chat_bubble_outline_rounded,
              size: 20, color: AppColors.success),
          tooltip: 'مراسلة واتساب',
          onPressed: () => _openWhatsApp(context, item.phone),
        );

        final renewButton = FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(64, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () {
            if (onRenewTap != null) {
              onRenewTap!(item);
            } else {
              _showMemberDetailsDialog(context, item);
            }
          },
          child: const Text('تجديد'),
        );

        final badgeWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            badgeText,
            style: AppTextStyles.caption.copyWith(
              color: badgeTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onMemberTap != null
                ? onMemberTap!(item)
                : _showMemberDetailsDialog(context, item),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Ink(
              padding: EdgeInsets.all(isNarrow ? AppSpacing.sm + 2 : AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(27, 33, 48, 0.04),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                _getInitials(item.memberName),
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.memberName,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${item.phone} • ${item.packageName ?? "باقة عامة"}',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            badgeWidget,
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            callButton,
                            const SizedBox(width: 4),
                            whatsAppButton,
                            const SizedBox(width: 6),
                            renewButton,
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            _getInitials(item.memberName),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.memberName,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.phone} • ${item.packageName ?? "باقة عامة"}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ينتهي: ${AppDateUtils.formatShortDate(item.endDate)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textDisabled,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            badgeWidget,
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                callButton,
                                whatsAppButton,
                                const SizedBox(width: 4),
                                renewButton,
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        );
  }

  (String text, Color bg, Color textColor) _getDaysLeftBadge(int daysLeft) {
    if (daysLeft <= 0) {
      return ('اليوم', AppColors.errorTint, AppColors.error);
    } else if (daysLeft == 1) {
      return ('غداً', AppColors.warningTint, AppColors.warning);
    } else {
      return ('$daysLeft أيام', AppColors.warningTint, AppColors.warning);
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]} ${parts[1][0]}';
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, 1);
    }
    return '?';
  }

  void _showMemberDetailsDialog(BuildContext context, ExpiringSubscription item) {
    showDialog(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (ctx) => AlertDialog(
        title: Text(item.memberName, style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الهاتف: ${item.phone}', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('الباقة: ${item.packageName ?? "باقة عامة"}',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'تاريخ الانتهاء: ${AppDateUtils.formatShortDate(item.endDate)}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'المتبقي: ${item.daysLeft <= 0 ? "ينتهي اليوم" : "${item.daysLeft} أيام"}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: item.daysLeft <= 0 ? AppColors.error : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Symbols.call_rounded, size: 18),
            label: const Text('اتصال'),
            onPressed: () {
              Navigator.pop(ctx);
              _makeCall(context, item.phone);
            },
          ),
          TextButton.icon(
            icon: const Icon(Symbols.chat_bubble_outline_rounded, size: 18),
            label: const Text('واتساب'),
            onPressed: () {
              Navigator.pop(ctx);
              _openWhatsApp(context, item.phone);
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
