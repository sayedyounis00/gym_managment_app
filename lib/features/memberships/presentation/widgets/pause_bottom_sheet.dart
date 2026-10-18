import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/widgets/app_button.dart';
import 'package:gym_managment_app/core/widgets/app_text_field.dart';
import 'package:gym_managment_app/core/widgets/date_field.dart';
import '../cubit/pause/pause_cubit.dart';
import '../cubit/pause/pause_state.dart';

class PauseBottomSheet extends StatefulWidget {
  final int memberId;
  final String memberName;

  const PauseBottomSheet({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int memberId,
    required String memberName,
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
        create: (_) => sl<PauseCubit>()..init(memberId),
        child: PauseBottomSheet(
          memberId: memberId,
          memberName: memberName,
        ),
      ),
    );
  }

  @override
  State<PauseBottomSheet> createState() => _PauseBottomSheetState();
}

class _PauseBottomSheetState extends State<PauseBottomSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PauseCubit, PauseState>(
      listener: (context, state) {
        if (state.isSuccess) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.pause_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('تم إيقاف اشتراك ${widget.memberName} مؤقتاً'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.paused,
            ),
          );
          Navigator.of(context).pop(true);
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
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                              color: AppColors.pausedTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pause_circle_rounded,
                              color: AppColors.paused,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إيقاف الاشتراك مؤقتاً',
                                  style: AppTextStyles.titleLarge,
                                ),
                                Text(
                                  widget.memberName,
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

                      // Date
                      DateField(
                        label: 'تاريخ الإيقاف',
                        value: state.pauseDate,
                        onChanged: (date) => context.read<PauseCubit>().setPauseDate(date),
                        helperText: 'لا تحتسب أيام الإيقاف كأيام منتهية من الاشتراك',
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Reason
                      AppTextField(
                        label: 'سبب الإيقاف (اختياري)',
                        hint: 'مثال: سفر، إصابة، امتحانات...',
                        controller: _reasonController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Confirm button
                      AppButton(
                        label: 'تأكيد الإيقاف المؤقت',
                        icon: Icons.pause_circle_rounded,
                        isLoading: state.isSubmitting,
                        isFullWidth: true,
                        onPressed: () {
                          context.read<PauseCubit>().pause(
                                memberId: widget.memberId,
                                pauseDate: state.pauseDate,
                                reason: _reasonController.text.trim().isEmpty
                                    ? null
                                    : _reasonController.text.trim(),
                              );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
