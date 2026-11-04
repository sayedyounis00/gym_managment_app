import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/arabic_search_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/member_balance.dart';

class BalanceTile extends StatelessWidget {
  final MemberBalance balance;
  final DateTime? selectedMonth;
  final VoidCallback onTap;

  const BalanceTile({
    super.key,
    required this.balance,
    this.selectedMonth,
    required this.onTap,
  });

  static const Map<int, String> arabicMonthNames = {
    1: 'يناير',
    2: 'فبراير',
    3: 'مارس',
    4: 'أبريل',
    5: 'مايو',
    6: 'يونيو',
    7: 'يوليو',
    8: 'أغسطس',
    9: 'سبتمبر',
    10: 'أكتوبر',
    11: 'نوفمبر',
    12: 'ديسمبر',
  };

  static String getMonthName(DateTime date) {
    return arabicMonthNames[date.month] ?? '${date.month}';
  }

  static String formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  static String formatPhoneForWhatsApp(String phone) {
    var digits = ArabicSearchUtils.normalizePhone(phone);
    if (digits.startsWith('0') && digits.length == 11) {
      return '20${digits.substring(1)}';
    } else if (digits.startsWith('20') && digits.length == 12) {
      return digits;
    }
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    return digits;
  }

  static String buildWhatsAppMessage({
    required String monthName,
    required double amount,
  }) {
    final amountStr = formatAmount(amount);
    return 'السلام عليكم ورحمة الله وبركاته،\n\n'
        'الكابتن أحمد بيفكّر حضرتك بالمستحقات المتبقية عن شهر $monthName.\n\n'
        'إجمالي المبلغ المستحق: $amountStr جنيه.\n\n'
        'شكرًا لحضرتك، ونتمنى لك يومًا سعيدًا.';
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final targetDate = selectedMonth ?? DateTime.now();
    final monthName = getMonthName(targetDate);
    final message = buildWhatsAppMessage(
      monthName: monthName,
      amount: balance.remaining,
    );
    final cleanPhone = formatPhoneForWhatsApp(balance.memberPhone);

    if (cleanPhone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم هاتف المشترك غير متوفر')),
        );
      }
      return;
    }

    final encodedText = Uri.encodeComponent(message);
    final appUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
    final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح واتساب للرقم ${balance.memberPhone}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            // 1. Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.errorTint,
              backgroundImage: balance.memberAvatarUrl != null
                  ? NetworkImage(balance.memberAvatarUrl!)
                  : null,
              child: balance.memberAvatarUrl == null
                  ? Text(
                      balance.memberName.isNotEmpty ? balance.memberName[0] : '؟',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm + 2),

            // 2. Name & package
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    balance.memberName,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (balance.activePackageName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      balance.activePackageName!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // 3. Outstanding remaining amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.format(balance.remaining),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'مستحق',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),

            // 4. WhatsApp shortcut button
            IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.whatsapp,
                size: 20,
                color: Color(0xFF25D366),
              ),
              tooltip: 'مراسلة واتساب',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _openWhatsApp(context),
            ),
          ],
        ),
      ),
    );
  }
}
