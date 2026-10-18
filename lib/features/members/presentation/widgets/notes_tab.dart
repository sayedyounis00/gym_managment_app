import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/widgets/confirm_dialog.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_note.dart';

class NotesTab extends StatelessWidget {
  final List<MemberNote> notes;
  final ValueChanged<String> onAddNote;
  final void Function(int id, String text) onUpdateNote;
  final ValueChanged<int> onDeleteNote;

  const NotesTab({
    super.key,
    required this.notes,
    required this.onAddNote,
    required this.onUpdateNote,
    required this.onDeleteNote,
  });

  void _showAddEditDialog(BuildContext context, [MemberNote? note]) {
    final controller = TextEditingController(text: note?.note ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          title: Text(
            note == null ? 'إضافة ملاحظة جديدة' : 'تعديل الملاحظة',
            style: AppTextStyles.titleMedium,
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'اكتب الملاحظة هنا...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDisabled,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  if (note == null) {
                    onAddNote(text);
                  } else {
                    onUpdateNote(note.id, text);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text(note == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الملاحظات الخاصة (${notes.length})',
              style: AppTextStyles.titleMedium,
            ),
            OutlinedButton.icon(
              onPressed: () => _showAddEditDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة ملاحظة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                backgroundColor: AppColors.primaryLight,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (notes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.note_alt_outlined,
                  size: 48,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'لا توجد ملاحظات مسجلة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final note = notes[index];
              final dateFormat = DateFormat('d MMMM yyyy - hh:mm a', 'ar');

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.infoTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sticky_note_2_rounded,
                            color: AppColors.info,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            dateFormat.format(note.createdAt),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: 'تعديل',
                          onPressed: () => _showAddEditDialog(context, note),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          tooltip: 'حذف',
                          onPressed: () async {
                            final confirm = await ConfirmDialog.show(
                              context,
                              title: 'حذف الملاحظة',
                              message: 'هل أنت متأكد من رغبتك في حذف هذه الملاحظة؟',
                              confirmLabel: 'حذف',
                              isDestructive: true,
                            );
                            if (confirm == true) {
                              onDeleteNote(note.id);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      note.note,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
