import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/widgets/app_button.dart';
import 'package:gym_managment_app/core/widgets/app_text_field.dart';
import 'package:gym_managment_app/core/widgets/money_field.dart';
import 'package:gym_managment_app/core/widgets/segmented_selector.dart';
import '../cubit/package_form/package_form_cubit.dart';
import '../cubit/package_form/package_form_state.dart';

class AddEditPackagePage extends StatefulWidget {
  final int? packageId;

  const AddEditPackagePage({super.key, this.packageId});

  @override
  State<AddEditPackagePage> createState() => _AddEditPackagePageState();
}

class _AddEditPackagePageState extends State<AddEditPackagePage> {
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PackageFormCubit>().init(widget.packageId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PackageFormCubit, PackageFormState>(
      listener: (context, state) {
        if (_nameController.text.isEmpty && state.name.isNotEmpty) {
          _nameController.text = state.name;
        }
        if (_durationController.text.isEmpty && state.durationValue > 0) {
          _durationController.text = state.durationValue.toString();
        }

        if (state.isSuccess) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(state.isEditMode ? 'تم تعديل الباقة بنجاح' : 'تم إضافة الباقة بنجاح'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(state.isEditMode ? 'تعديل الباقة' : 'إنشاء باقة جديدة'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Package Name
                          AppTextField(
                            label: 'اسم الباقة',
                            hint: 'مثال: باقة اللياقة الشهرية، باقة 3 شهور...',
                            controller: _nameController,
                            errorText: state.nameError,
                            onChanged: (val) => context.read<PackageFormCubit>().setName(val),
                            prefixIcon: const Icon(Icons.card_membership_rounded),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 2. Price
                          MoneyField(
                            label: 'السعر',
                            initialValue: state.price,
                            errorText: state.priceError,
                            onChanged: (val) => context.read<PackageFormCubit>().setPrice(val),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 3. Duration: Value + Unit Selector
                          Text(
                            'المدة',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs + 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Number field
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _durationController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (val) {
                                    final parsed = int.tryParse(val) ?? 1;
                                    context.read<PackageFormCubit>().setDurationValue(parsed);
                                  },
                                  decoration: InputDecoration(
                                    hintText: '1',
                                    errorText: state.durationError,
                                    prefixIcon: const Icon(
                                      Icons.timer_outlined,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),

                              // Unit selector: شهور / أيام
                              Expanded(
                                flex: 3,
                                child: SegmentedSelector<String>(
                                  selectedValue: state.durationUnit,
                                  onSelected: (unit) =>
                                      context.read<PackageFormCubit>().setDurationUnit(unit),
                                  segments: const [
                                    SegmentItem(value: 'months', label: 'شهور'),
                                    SegmentItem(value: 'days', label: 'أيام'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // 4. Active Toggle Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'حالة الباقة',
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    Text(
                                      state.isActive
                                          ? 'الباقة مفعلة ومتاحة للتجديد والاشتراك'
                                          : 'الباقة معطلة ولن تظهر في قائمة التجديد',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: state.isActive,
                                  onChanged: (val) =>
                                      context.read<PackageFormCubit>().setIsActive(val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sticky Bottom Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: state.isEditMode ? 'حفظ التعديلات' : 'حفظ الباقة',
                              icon: Icons.check_rounded,
                              isLoading: state.isSaving,
                              onPressed: () => context.read<PackageFormCubit>().save(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppButton.outlined(
                              label: 'إلغاء',
                              onPressed: () => context.pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
