import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../cubit/export_cubit.dart';
import '../cubit/export_state.dart';

class ExportSheet extends StatelessWidget {
  final MemberStatusType? initialStatusFilter;

  const ExportSheet({super.key, this.initialStatusFilter});

  static Future<void> show(
    BuildContext context, {
    MemberStatusType? initialStatusFilter,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider(
        create: (_) => sl<ExportCubit>()..setStatusFilter(initialStatusFilter),
        child: ExportSheet(initialStatusFilter: initialStatusFilter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportCubit, ExportState>(
      listener: (context, state) {
        if (state.status == ExportStatus.success) {
          Navigator.of(context).pop();
          if (state.successMessage != null) {
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
          }
        } else if (state.status == ExportStatus.failure) {
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
                      state.errorMessage ?? 'حدث خطأ أثناء التصدير',
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
        final cubit = context.read<ExportCubit>();

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
            top: AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تصدير بيانات المشتركين',
                    style: AppTextStyles.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                'تصفية حسب حالة المشترك:',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'الكل',
                      isSelected: state.statusFilter == null,
                      onTap: () => cubit.setStatusFilter(null),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      label: 'نشط',
                      isSelected: state.statusFilter == MemberStatusType.active,
                      onTap: () => cubit.setStatusFilter(MemberStatusType.active),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      label: 'ينتهي قريباً',
                      isSelected: state.statusFilter == MemberStatusType.expiringSoon,
                      onTap: () => cubit.setStatusFilter(MemberStatusType.expiringSoon),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      label: 'منتهي',
                      isSelected: state.statusFilter == MemberStatusType.expired,
                      onTap: () => cubit.setStatusFilter(MemberStatusType.expired),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      label: 'موقوف',
                      isSelected: state.statusFilter == MemberStatusType.paused,
                      onTap: () => cubit.setStatusFilter(MemberStatusType.paused),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Include Notes Checkbox
              Material(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: CheckboxListTile(
                  value: state.includeNotes,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  title: Text(
                    'تضمين الملاحظات',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'إضافة ملاحظات المشتركين المسجلة في ملف التصدير',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  onChanged: state.isExporting
                      ? null
                      : (val) => cubit.toggleIncludeNotes(val ?? false),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // CSV Export Button
              AppButton(
                label: 'تصدير كملف Excel (CSV)',
                variant: AppButtonVariant.primary,
                leadingIcon: Icons.table_chart_rounded,
                isFullWidth: true,
                isLoading: state.isExporting,
                onPressed: state.isExporting ? null : () => cubit.exportCsv(),
              ),
              const SizedBox(height: AppSpacing.sm),

              // PDF Export Button
              AppButton(
                label: 'تصدير كملف PDF',
                variant: AppButtonVariant.outlined,
                leadingIcon: Icons.picture_as_pdf_rounded,
                isFullWidth: true,
                isLoading: state.isExporting,
                onPressed: state.isExporting ? null : () => cubit.exportPdf(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
    );
  }
}
