import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/money_field.dart';
import 'package:gym_managment_app/features/finance/domain/entities/expense.dart';
import 'package:gym_managment_app/features/finance/domain/entities/finance_enums.dart';
import '../cubit/add_expense/add_expense_cubit.dart';
import '../cubit/add_expense/add_expense_state.dart';
import '../widgets/category_chips.dart';
import '../widgets/method_chips.dart';

class AddExpensePage extends StatelessWidget {
  final Expense? initialExpense;

  const AddExpensePage({super.key, this.initialExpense});

  static Future<bool?> show(BuildContext context, {Expense? initialExpense}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExpensePage(initialExpense: initialExpense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddExpenseCubit>()..init(initialExpense: initialExpense),
      child: const _AddExpenseView(),
    );
  }
}

class _AddExpenseView extends StatelessWidget {
  const _AddExpenseView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddExpenseCubit, AddExpenseState>(
      listener: (context, state) {
        if (state.isSuccess) {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<AddExpenseCubit>();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'تسجيل مصروف جديد',
              style: AppTextStyles.titleLarge,
            ),
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Category Chips
                        ExpenseCategoryChips(
                          selectedCategory: state.category,
                          onSelected: (cat) => cubit.setCategory(cat),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 2. Custom Label when 'other'
                        if (state.category == ExpenseCategory.other) ...[
                          Text(
                            'مسمى المصروف (مطلوب)',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            initialValue: state.customLabel,
                            onChanged: (text) => cubit.setCustomLabel(text),
                            decoration: InputDecoration(
                              hintText: 'مثال: أدوات نظافة، صيانة أجهزة...',
                              filled: true,
                              fillColor: AppColors.surface,
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
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 3. Amount Field
                        MoneyField(
                          label: 'قيمة المصروف',
                          initialValue: state.amount,
                          onChanged: (val) => cubit.setAmount(val),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 4. Date Picker
                        Text(
                          'تاريخ المصروف',
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
                              initialDate: state.date,
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
                              color: AppColors.surface,
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
                                  DateFormat('yyyy/MM/dd', 'ar').format(state.date),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 5. Payment Method Chips
                        FinanceMethodChips(
                          selectedMethod: state.method,
                          onSelected: (m) => cubit.setMethod(m),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 6. Notes Field
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
                          maxLines: 2,
                          onChanged: (text) => cubit.setNote(text),
                          decoration: InputDecoration(
                            hintText: 'تفاصيل إضافية عن الفاتورة أو المصروف...',
                            filled: true,
                            fillColor: AppColors.surface,
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
                        const SizedBox(height: AppSpacing.md),

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
                        ],
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Bar
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: const Border(
                      top: BorderSide(color: AppColors.border, width: 1.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'حفظ المصروف',
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
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
