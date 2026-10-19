import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/widgets/exit_confirmation_dialog.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/utils/responsive_utils.dart';
import 'package:gym_managment_app/core/widgets/app_button.dart';
import 'package:gym_managment_app/core/widgets/app_text_field.dart';
import 'package:gym_managment_app/core/widgets/confirm_dialog.dart';
import 'package:gym_managment_app/core/widgets/segmented_selector.dart';
import 'package:gym_managment_app/core/widgets/skeletons/skeletons.dart';
import '../../domain/entities/gender.dart';
import '../cubit/member_form/member_form_cubit.dart';
import '../cubit/member_form/member_form_state.dart';
import '../widgets/member_photo_picker.dart';

class AddEditMemberPage extends StatefulWidget {
  final int? memberId;

  const AddEditMemberPage({super.key, this.memberId});

  @override
  State<AddEditMemberPage> createState() => _AddEditMemberPageState();
}

class _AddEditMemberPageState extends State<AddEditMemberPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _noteController = TextEditingController();

  bool _initializedControllers = false;

  @override
  void initState() {
    super.initState();
    context.read<MemberFormCubit>().init(widget.memberId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _syncControllers(MemberFormEditing state) {
    if (!_initializedControllers) {
      _nameController.text = state.name;
      _phoneController.text = state.phone;
      _ageController.text = state.age?.toString() ?? '';
      _weightController.text = state.weightKg != null
          ? (state.weightKg! % 1 == 0
              ? state.weightKg!.toInt().toString()
              : state.weightKg!.toString())
          : '';
      _heightController.text = state.heightCm != null
          ? (state.heightCm! % 1 == 0
              ? state.heightCm!.toInt().toString()
              : state.heightCm!.toString())
          : '';
      _noteController.text = state.initialNote ?? '';
      _initializedControllers = true;
    }
  }

  Future<bool> _onWillPop(bool isDirty) async {
    if (!isDirty) return true;
    final discard = await ConfirmDialog.show(
      context,
      title: 'تجاهل التغييرات؟',
      message: 'لديك بيانات غير محفوظة، هل أنت متأكد من رغبتك في الرجوع دون حفظ؟',
      confirmLabel: 'تجاهل التغييرات',
      cancelLabel: 'متابعة التعديل',
      isDestructive: true,
    );
    return discard == true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MemberFormCubit, MemberFormState>(
      listener: (context, state) {
        if (state is MemberFormSaved) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                state.isEdit ? 'تم تحديث بيانات المشترك بنجاح' : 'تمت إضافة المشترك بنجاح',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go('/members/${state.memberId}');
          }
        } else if (state is MemberFormFailure) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is MemberFormEditing) {
          _syncControllers(state);
        }

        final isDirty = state is MemberFormEditing && state.isDirty;
        final isEdit = state is MemberFormEditing && state.isEditMode;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final canExit = await _onWillPop(isDirty);
            if (canExit && context.mounted) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                final shouldExit = await showExitConfirmationDialog(context);
                if (shouldExit == true) {
                  await SystemNavigator.pop();
                }
              }
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                isEdit ? 'تعديل بيانات المشترك' : 'إضافة مشترك جديد',
                style: AppTextStyles.titleLarge,
              ),
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 2,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'رجوع',
                onPressed: () async {
                  final canExit = await _onWillPop(isDirty);
                  if (canExit && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            body: state is! MemberFormEditing
                ? const MemberFormSkeleton()
                : SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: ResponsiveCenteredContainer(
                              maxWidth: 600,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Photo section
                                  MemberPhotoPicker(
                                    existingPhotoPath: state.existingPhotoPath,
                                    newPhotoFile: state.newPhotoFile,
                                    name: state.name,
                                    onPhotoSelected: (file) {
                                      context.read<MemberFormCubit>().setPhoto(file);
                                    },
                                    onPhotoRemoved: () {
                                      context.read<MemberFormCubit>().removePhoto();
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // General error banner if present
                                  if (state.errors.containsKey('general')) ...[
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorTint,
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                        border: Border.all(color: AppColors.error),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: AppColors.error),
                                          const SizedBox(width: AppSpacing.xs),
                                          Expanded(
                                            child: Text(
                                              state.errors['general']!,
                                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],

                                  // Basic Info Section
                                  Text(
                                    'البيانات الأساسية',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),

                                  // Name Field
                                  AppTextField(
                                    label: 'الاسم الكامل *',
                                    hint: 'مثال: أحمد محمد علي',
                                    controller: _nameController,
                                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                                    errorText: state.errors['name'],
                                    onChanged: (val) {
                                      context.read<MemberFormCubit>().updateName(val);
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Phone Field (forced LTR for digits)
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: AppTextField(
                                      label: 'رقم الهاتف *',
                                      hint: '01xxxxxxxxx',
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: const Icon(Icons.call_rounded, color: AppColors.textSecondary),
                                      errorText: state.errors['phone'],
                                      onChanged: (val) {
                                        context.read<MemberFormCubit>().updatePhone(val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Gender Selector
                                  Text(
                                    'الجنس *',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  SegmentedSelector<Gender?>(
                                    segments: const [
                                      SegmentItem(
                                        value: Gender.male,
                                        label: 'ذكر',
                                        icon: Icons.male_rounded,
                                      ),
                                      SegmentItem(
                                        value: Gender.female,
                                        label: 'أنثى',
                                        icon: Icons.female_rounded,
                                      ),
                                    ],
                                    selectedValue: state.gender,
                                    onSelected: (val) {
                                      if (val != null) {
                                        context.read<MemberFormCubit>().updateGender(val);
                                      }
                                    },
                                  ),
                                  if (state.errors.containsKey('gender')) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      state.errors['gender']!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.xl),

                                  // Body Info Section
                                  Text(
                                    'بيانات الجسم (اختياري)',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),

                                  // 3-Column Row for Age, Weight, Height
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: AppTextField(
                                          label: 'العمر',
                                          hint: 'سنة',
                                          controller: _ageController,
                                          keyboardType: TextInputType.number,
                                          errorText: state.errors['age'],
                                          onChanged: (val) {
                                            context.read<MemberFormCubit>().updateAge(val);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: AppTextField(
                                          label: 'الوزن',
                                          hint: 'كجم',
                                          controller: _weightController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          errorText: state.errors['weight'],
                                          onChanged: (val) {
                                            context.read<MemberFormCubit>().updateWeight(val);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: AppTextField(
                                          label: 'الطول',
                                          hint: 'سم',
                                          controller: _heightController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          errorText: state.errors['height'],
                                          onChanged: (val) {
                                            context.read<MemberFormCubit>().updateHeight(val);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  // Notes Section (Visible on Create Flow)
                                  if (!isEdit) ...[
                                    Text(
                                      'ملاحظة أولية (اختياري)',
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(
                                      label: 'ملاحظة خاصة بالمشترك',
                                      hint: 'أي تفاصيل صحية أو تدريبية خاصة...',
                                      controller: _noteController,
                                      maxLines: 3,
                                      onChanged: (val) {
                                        context.read<MemberFormCubit>().updateInitialNote(val);
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Sticky Bottom Action Bar
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              top: BorderSide(color: AppColors.border, width: 1),
                            ),
                          ),
                          child: ResponsiveCenteredContainer(
                            maxWidth: 600,
                            child: Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: isEdit ? 'حفظ التعديلات' : 'إضافة المشترك',
                                    variant: AppButtonVariant.primary,
                                    isLoading: state.isSaving,
                                    onPressed: () {
                                      context.read<MemberFormCubit>().save();
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: AppButton(
                                    label: 'إلغاء',
                                    variant: AppButtonVariant.outlined,
                                    onPressed: () async {
                                      final canExit = await _onWillPop(isDirty);
                                      if (canExit && context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
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
