import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/utils/currency_formatter.dart';
import 'package:gym_managment_app/core/widgets/app_button.dart';
import 'package:gym_managment_app/core/widgets/date_field.dart';
import 'package:gym_managment_app/core/widgets/money_field.dart';
import 'package:gym_managment_app/core/widgets/payment_method_chips.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import '../../domain/entities/membership_package.dart';
import '../cubit/renew/renew_cubit.dart';
import '../cubit/renew/renew_state.dart';

class RenewBottomSheet extends StatelessWidget {
  final int memberId;
  final String memberName;
  final int? preselectedPackageId;

  const RenewBottomSheet({
    super.key,
    required this.memberId,
    required this.memberName,
    this.preselectedPackageId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int memberId,
    required String memberName,
    int? preselectedPackageId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => BlocProvider(
        create: (_) => sl<RenewCubit>()
          ..init(
            memberId: memberId,
            memberName: memberName,
            preselectedPackageId: preselectedPackageId,
          ),
        child: RenewBottomSheet(
          memberId: memberId,
          memberName: memberName,
          preselectedPackageId: preselectedPackageId,
        ),
      ),
    );
  }

  void _showPackagePicker(BuildContext context, List<MembershipPackage> packages, MembershipPackage? selected) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (pickerCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر الباقة',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: packages.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final pkg = packages[index];
                      final isSelected = pkg.id == selected?.id;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            context.read<RenewCubit>().selectPackage(pkg);
                            Navigator.of(pickerCtx).pop();
                          },
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryLight : AppColors.secondaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.card_membership_rounded,
                              color: isSelected ? AppColors.primary : AppColors.secondary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            pkg.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            pkg.formattedDuration,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(pkg.price),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RenewCubit, RenewState>(
      listener: (context, state) {
        if (state.isSuccess) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('تم تجديد اشتراك ${state.memberName} بنجاح'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(state.errorMessage!),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const SizedBox(
            height: 240,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.autorenew_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تجديد الاشتراك',
                                  style: AppTextStyles.titleLarge,
                                ),
                                Text(
                                  memberName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'إغلاق',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 1. Package selector
                      Text(
                        'الباقة',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      InkWell(
                        onTap: () => _showPackagePicker(
                          context,
                          state.activePackages,
                          state.selectedPackage,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.card_membership_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  state.selectedPackage?.name ?? 'اختر باقة...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: state.selectedPackage != null
                                        ? AppColors.textPrimary
                                        : AppColors.textDisabled,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (state.selectedPackage != null)
                                Text(
                                  CurrencyFormatter.format(state.selectedPackage!.price),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(
                                Icons.arrow_drop_down_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 2 & 3. Dates: Start Date & Live End Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DateField(
                              label: 'تاريخ البدء',
                              value: state.startDate,
                              onChanged: (date) => context.read<RenewCubit>().setStartDate(date),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DateField(
                              label: 'تاريخ الانتهاء',
                              value: state.endDate,
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '* يحسب تاريخ الانتهاء تلقائياً حسب مدة الباقة المختارة',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 4. Amount Paid
                      MoneyField(
                        label: 'المبلغ المدفوع',
                        initialValue: state.amountPaid,
                        onChanged: (val) => context.read<RenewCubit>().setAmountPaid(val),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 5. Payment method chips
                      PaymentMethodChips(
                        selectedMethod: state.paymentMethod,
                        onSelected: (method) => context.read<RenewCubit>().setPaymentMethod(method),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 6. Remaining amount live indicator
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: state.remainingAmount > 0 ? AppColors.warningTint : AppColors.successTint,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: state.remainingAmount > 0 ? AppColors.warning : AppColors.success,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (state.remainingAmount > 0) ...[
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.xs + 2),
                                ],
                                Text(
                                  state.remainingAmount > 0 ? 'المبلغ المتبقي دين:' : 'حالة السداد:',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: state.remainingAmount > 0 ? AppColors.warning : AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (state.remainingAmount > 0)
                              Text(
                                CurrencyFormatter.format(state.remainingAmount),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              const StatusChip(
                                label: 'تم الدفع بالكامل',
                                icon: Icons.check_circle_rounded,
                                color: AppColors.success,
                                backgroundColor: AppColors.surface,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 7. Confirm Button
                      AppButton(
                        label: 'تأكيد التجديد',
                        icon: Icons.check_rounded,
                        isLoading: state.isSubmitting,
                        isFullWidth: true,
                        onPressed: () => context.read<RenewCubit>().submit(),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
