import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';
import 'member_avatar.dart';

class MemberCard extends StatelessWidget {
  final MemberSummary member;
  final VoidCallback onTap;

  const MemberCard({
    super.key,
    required this.member,
    required this.onTap,
  });

  String _buildExpiryText() {
    if (member.isSuspended) {
      return 'العضوية موقوفة حالياً';
    }
    if (member.subscriptionEndDate == null) {
      return 'لا يوجد اشتراك نشط';
    }

    final days = member.daysLeft;
    if (days == null) return '';

    if (days < 0) {
      return 'انتهى منذ ${days.abs()} يوم (${AppDateUtils.formatShortDate(member.subscriptionEndDate!)})';
    } else if (days == 0) {
      return 'ينتهي اليوم (${AppDateUtils.formatShortDate(member.subscriptionEndDate!)})';
    } else {
      return 'ينتهي بعد $days يوم (${AppDateUtils.formatShortDate(member.subscriptionEndDate!)})';
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
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MemberAvatar(
                photoPath: member.photoPath,
                name: member.name,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        StatusChip.memberStatus(member.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${member.phone}${member.packageName != null ? ' · ${member.packageName}' : ''}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildExpiryText(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: member.status == MemberStatusType.expired
                            ? AppColors.error
                            : member.status == MemberStatusType.expiringSoon
                                ? AppColors.warning
                                : AppColors.textSecondary,
                        fontWeight: member.status == MemberStatusType.expiringSoon
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF25D366),
                  size: 20,
                ),
                tooltip: 'مراسلة واتساب',
                onPressed: () => _openWhatsApp(context, member.phone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
