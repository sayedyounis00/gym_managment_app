import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/payment_status_chip.dart';
import '../cubit/add_payment/add_payment_cubit.dart';
import '../cubit/add_payment/add_payment_state.dart';
import 'method_chips.dart';

class AddPaymentSheet extends StatelessWidget {
  final int? preselectedMemberId;

  const AddPaymentSheet({
    super.key,
    this.preselectedMemberId,
  });

  static Future<bool?> show(
    BuildContext context, {
    int? preselectedMemberId,
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
        create: (_) => sl<AddPaymentCubit>()..init(preselectedMemberId: preselectedMemberId),
        child: AddPaymentSheet(preselectedMemberId: preselectedMemberId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddPaymentCubit, AddPaymentState>(
      listener: (context, state) {
        if (state.isSuccess) {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<AddPaymentCubit>();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs + 3),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'تسجيل دفعة اشتراك',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 1. Member Selector
                Text(
                  'المشترك',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: state.selectedMemberId,
                      dropdownColor: AppColors.surface,
                      hint: const Text('اختر المشترك...'),
                      items: state.allMembers.map<DropdownMenuItem<int>>((Member m) {
                        return DropdownMenuItem<int>(
                          value: m.id,
                          child: Text(
                            m.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          cubit.selectMember(val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Month / Period Selector
                if (state.periodOptions.isNotEmpty) ...[
                  Text(
                    'ربط بالشهر / القسط',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MemberPeriodOption?>(
                        isExpanded: true,
                        value: state.selectedPeriod,
                        dropdownColor: AppColors.surface,
                        hint: const Text('دفعة عامة (بدون ربط)'),
                        items: [
                          const DropdownMenuItem<MemberPeriodOption?>(
                            value: null,
                            child: Text('دفعة عامة (بدون ربط بقسط محدد)'),
                          ),
                          ...state.periodOptions.map((opt) {
                            return DropdownMenuItem<MemberPeriodOption?>(
                              value: opt,
                              child: Text(
                                '${opt.label} · متبقي: ${CurrencyFormatter.format(opt.remaining)}',
                                style: TextStyle(
                                  fontWeight: opt.remaining > 0 ? FontWeight.w600 : FontWeight.w400,
                                  color: opt.remaining > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (opt) => cubit.selectPeriod(opt),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 3. Amount MoneyField
                MoneyField(
                  label: 'المبلغ المدفوع',
                  initialValue: state.amount,
                  onChanged: (val) => cubit.setAmount(val),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Live Remaining & Post-payment Status Card
                if (state.selectedPeriod != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المتبقي بعد هذه الدفعة:',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(state.remainingAfterPayment),
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: state.remainingAfterPayment > 0
                                    ? AppColors.error
                                    : AppColors.success,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        PaymentStatusChip(status: state.postPaymentStatus),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 5. Payment Method Chips
                FinanceMethodChips(
                  selectedMethod: state.method,
                  onSelected: (m) => cubit.setMethod(m),
                ),
                const SizedBox(height: AppSpacing.md),

                // 6. Date Picker Field
                Text(
                  'تاريخ الدفع',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.paidAt,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      cubit.setDate(picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          DateFormat('yyyy/MM/dd', 'ar').format(state.paidAt),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 7. Notes Field
                Text(
                  'ملاحظات إضافية (اختياري)',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  initialValue: state.note,
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  onChanged: (text) => cubit.setNote(text),
                  decoration: InputDecoration(
                    hintText: 'ملاحظات حول الدفعة...',
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
                const SizedBox(height: AppSpacing.lg),

                // Error Banner
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: AppColors.errorTint,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Action Buttons: Equal width, 12 gap, primary on start side (right in RTL)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'تأكيد الدفعة',
                        height: 52,
                        isLoading: state.isSubmitting,
                        onPressed: () => cubit.submit(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.outlined(
                        label: 'إلغاء',
                        height: 52,
                        onPressed: state.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
