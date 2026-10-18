import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/ledger_entry.dart';

class VoidConfirmationDialog extends StatefulWidget {
  final LedgerEntry entry;

  const VoidConfirmationDialog({
    super.key,
    required this.entry,
  });

  static Future<String?> show(
    BuildContext context, {
    required LedgerEntry entry,
  }) {
    return showDialog<String?>(
      context: context,
      builder: (ctx) => VoidConfirmationDialog(entry: entry),
    );
  }

  @override
  State<VoidConfirmationDialog> createState() => _VoidConfirmationDialogState();
}

class _VoidConfirmationDialogState extends State<VoidConfirmationDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.entry.type.value == 'income';
    final typeName = isIncome ? 'دفعة' : 'مصروف';
    final titleText = 'إلغاء $typeName ${widget.entry.title} بقيمة ${CurrencyFormatter.format(widget.entry.amount)}؟';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: const BoxDecoration(
              color: AppColors.errorTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'تأكيد الإلغاء',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'سيتم استبعاد هذه المعاملة من الحسابات والمجاميع، مع بقائها في السجل كمعاملة ملغاة للتدقيق.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'سبب الإلغاء (اختياري)',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'مثال: خطأ في إدخال المبلغ...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
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
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(AppSpacing.md),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'إلغاء المعاملة',
                variant: AppButtonVariant.destructive,
                height: 44,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(_reasonController.text.trim());
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton.outlined(
                label: 'تراجع',
                height: 44,
                onPressed: () => Navigator.of(context).pop(null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
