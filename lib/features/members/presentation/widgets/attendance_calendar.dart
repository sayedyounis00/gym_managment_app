import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'package:gym_managment_app/features/members/domain/entities/attendance_record.dart';

class AttendanceCalendar extends StatelessWidget {
  final DateTime currentMonth;
  final List<DateTime> attendedDays;
  final List<AttendanceRecord> records;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const AttendanceCalendar({
    super.key,
    required this.currentMonth,
    required this.attendedDays,
    required this.records,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy', 'ar');
    final monthTitle = monthFormat.format(currentMonth);

    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday;
    // In Dart DateTime, 1 = Mon, 7 = Sun. For Arabic calendar starting Saturday:
    // Sat = 6 -> offset 0
    // Sun = 7 -> offset 1
    // Mon = 1 -> offset 2
    // Tue = 2 -> offset 3
    // Wed = 3 -> offset 4
    // Thu = 4 -> offset 5
    // Fri = 5 -> offset 6
    final startOffset = (firstDayWeekday + 1) % 7;

    final attendedDayNumbers = attendedDays.map((d) => d.day).toSet();
    final now = DateTime.now();
    final isCurrentMonth = now.year == currentMonth.year && now.month == currentMonth.month;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'الشهر السابق',
                onPressed: onPreviousMonth,
              ),
              Text(
                monthTitle,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'الشهر التالي',
                onPressed: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayHeader('س'),
              _WeekdayHeader('ح'),
              _WeekdayHeader('ن'),
              _WeekdayHeader('ث'),
              _WeekdayHeader('ر'),
              _WeekdayHeader('خ'),
              _WeekdayHeader('ج'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.xs),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startOffset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }
              final dayNumber = index - startOffset + 1;
              final isAttended = attendedDayNumbers.contains(dayNumber);
              final isToday = isCurrentMonth && now.day == dayNumber;

              return Container(
                decoration: BoxDecoration(
                  color: isAttended
                      ? AppColors.primaryLight
                      : isToday
                          ? AppColors.surfaceVariant
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isAttended || isToday
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isAttended
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (isAttended)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(
            'سجل الحضور لهذا الشهر (${records.length} يوم)',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  'لم يتم تسجيل حضور في هذا الشهر',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppColors.border,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final rec = records[index];
                final timeFormat = DateFormat('hh:mm a', 'ar');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          AppDateUtils.formatShortDate(rec.checkInTime),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Text(
                        timeFormat.format(rec.checkInTime),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
