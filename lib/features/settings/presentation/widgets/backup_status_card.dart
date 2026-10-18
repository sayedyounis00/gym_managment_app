import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/backup_info.dart';

class BackupStatusCard extends StatelessWidget {
  final BackupInfo? lastBackup;
  final bool isLoading;

  const BackupStatusCard({
    super.key,
    required this.lastBackup,
    this.isLoading = false,
  });

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 ك.ب';
    final kb = bytes / 1024.0;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} ك.ب';
    }
    final mb = kb / 1024.0;
    return '${mb.toStringAsFixed(1)} م.ب';
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(date);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return 'منذ $months شهر';
    } else if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} ${diff.inDays == 1 ? "يوم" : "أيام"}';
    } else if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ${diff.inHours == 1 ? "ساعة" : "ساعات"}';
    } else if (diff.inMinutes > 0) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBackup = lastBackup != null;
    final isStale = !hasBackup ||
        DateTime.now().difference(lastBackup!.createdAt).inDays >= 7;

    final statusColor = isStale ? AppColors.warning : AppColors.success;
    final statusBgColor = isStale ? AppColors.warningTint : AppColors.successTint;
    final statusIcon = isStale
        ? (hasBackup ? Icons.warning_amber_rounded : Icons.info_outline_rounded)
        : Icons.check_circle_rounded;

    final title = !hasBackup
        ? 'لا توجد نسخة احتياطية'
        : (isStale ? 'النسخة الاحتياطية قديمة' : 'البيانات محمية بنسخة احتياطية');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isStale ? AppColors.warning.withValues(alpha: 0.3) : AppColors.border,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061B2130),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (hasBackup)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          _timeAgo(lastBackup!.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (hasBackup) ...[
                  Text(
                    'التاريخ: ${_formatDate(lastBackup!.createdAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (lastBackup!.memberCount > 0 || lastBackup!.fileSizeBytes > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'المشتركين: ${lastBackup!.memberCount} | الحجم: ${_formatBytes(lastBackup!.fileSizeBytes)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    'يُنصح بإنشاء نسخة احتياطية دورياً لضمان عدم فقدان بيانات المشتركين والاشتراكات.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
