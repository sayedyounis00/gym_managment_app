import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/loaders/liquid_glass_effect.dart';
import '../cubit/backup_cubit.dart';
import '../cubit/backup_state.dart';
import '../widgets/backup_status_card.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BackupCubit>()..init(),
      child: const _BackupView(),
    );
  }
}

class _BackupView extends StatelessWidget {
  const _BackupView();

  Future<void> _handleRestore(BuildContext context) async {
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['gymbak', 'zip'],
      );

      if (pickedFile == null || pickedFile.path == null) {
        return;
      }

      final filePath = pickedFile.path!;
      if (!context.mounted) return;

      final cubit = context.read<BackupCubit>();
      final validatedInfo = await cubit.validateBackup(filePath);
      if (validatedInfo == null || !context.mounted) return;

      final formattedDate =
          DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(validatedInfo.createdAt);

      final confirmed = await ConfirmDialog.show(
        context,
        title: 'استبدال البيانات الحالية',
        message:
            'النسخة الاحتياطية بتاريخ $formattedDate تحتوي على ${validatedInfo.memberCount} مشترك.\n\nسيتم استبدال جميع البيانات الحالية بالبيانات الموجودة في هذه النسخة. هل تريد المتابعة؟',
        confirmLabel: 'استعادة واستبدال',
        cancelLabel: 'إلغاء',
        isDestructive: true,
      );

      if (confirmed == true && context.mounted) {
        await cubit.restoreBackup(filePath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('حدث خطأ أثناء اختيار الملف: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BackupCubit, BackupState>(
      listener: (context, state) {
        if (state.status == BackupStatus.success && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      state.successMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state.status == BackupStatus.restoreSuccess) {
          // Navigate to dashboard and show success banner
          context.go(AppRoutes.dashboard);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'تمت استعادة البيانات بنجاح، وجرى تحديث الاشتراكات والتنبيهات.',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state.status == BackupStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(
                  'النسخ الاحتياطي والاستعادة',
                  style: AppTextStyles.titleLarge,
                ),
                backgroundColor: AppColors.surface,
                elevation: 0,
                scrolledUnderElevation: 2,
              ),
              body: Skeletonizer(
                enabled: state.status == BackupStatus.loading,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Status Card
                    BackupStatusCard(
                      lastBackup: state.lastBackup,
                      isLoading: state.isLoading,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Actions Section
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'إجراءات النسخ',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'يمكنك حفظ نسخة احتياطية من جميع المشتركين، الاشتراكات، والصور لمشاركتها أو حفظها في مكان آمن.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Primary action: Backup Now
                          AppButton(
                            label: 'نسخ احتياطي الآن',
                            variant: AppButtonVariant.primary,
                            leadingIcon: Icons.cloud_upload_rounded,
                            isFullWidth: true,
                            isLoading: state.status == BackupStatus.inProgress,
                            onPressed: state.isLoading
                                ? null
                                : () => context.read<BackupCubit>().createBackup(),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Secondary action: Restore from backup
                          AppButton(
                            label: 'استعادة من نسخة',
                            variant: AppButtonVariant.outlined,
                            leadingIcon: Icons.settings_backup_restore_rounded,
                            isFullWidth: true,
                            isLoading: false,
                            onPressed: state.isLoading
                                ? null
                                : () => _handleRestore(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Local Backups List (last 3 copies)
                    if (state.localBackups.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AppSpacing.xs,
                          bottom: AppSpacing.xs,
                        ),
                        child: Text(
                          'النسخ المحلية الأخيرة (آخر 3 نسخ)',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: state.localBackups.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.border,
                            ),
                            itemBuilder: (context, index) {
                              final item = state.localBackups[index];
                              final dateFormatted = DateFormat(
                                'yyyy/MM/dd - hh:mm a',
                                'ar',
                              ).format(item.createdAt);

                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: const Icon(
                                    Icons.folder_zip_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  item.fileName,
                                  style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '$dateFormatted | ${item.memberCount} مشترك',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.share_rounded,
                                        size: 20,
                                        color: AppColors.secondary,
                                      ),
                                      tooltip: 'مشاركة',
                                      onPressed: () => context
                                          .read<BackupCubit>()
                                          .shareBackup(item.filePath),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'حذف',
                                      onPressed: () async {
                                        final delConfirm = await ConfirmDialog.show(
                                          context,
                                          title: 'حذف النسخة الاحتياطية',
                                          message:
                                              'هل أنت متأكد من رغبتك في حذف النسخة ${item.fileName}؟',
                                          confirmLabel: 'حذف',
                                          cancelLabel: 'إلغاء',
                                          isDestructive: true,
                                        );
                                        if (delConfirm == true && context.mounted) {
                                          context
                                              .read<BackupCubit>()
                                              .deleteBackup(item.filePath);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Liquid glass full-screen progress loader during restore
            if (state.status == BackupStatus.restoreInProgress)
              Container(
                color: AppColors.overlay,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: LiquidGlassDecoration.card(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'جاري استعادة البيانات...',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'يرجى عدم إغلاق التطبيق أثناء نقل البيانات وفحص الجداول.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
