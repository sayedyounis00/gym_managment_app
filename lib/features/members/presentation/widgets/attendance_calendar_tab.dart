import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../cubit/attendance/attendance_cubit.dart';
import '../cubit/attendance/attendance_state.dart';

class AttendanceCalendarTab extends StatefulWidget {
  final int memberId;
  final bool isDailyPlanActive;
  final int? activeSubscriptionId;
  final VoidCallback? onAttendanceChanged;

  const AttendanceCalendarTab({
    super.key,
    required this.memberId,
    required this.isDailyPlanActive,
    this.activeSubscriptionId,
    this.onAttendanceChanged,
  });

  @override
  State<AttendanceCalendarTab> createState() => _AttendanceCalendarTabState();
}

class _AttendanceCalendarTabState extends State<AttendanceCalendarTab> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  bool _isAttended(DateTime day, Set<DateTime> attendedDates) {
    return attendedDates.any((d) => isSameDay(d, day));
  }

  Future<void> _onDaySelected(DateTime selectedDay, Set<DateTime> attendedDates) async {
    if (!widget.isDailyPlanActive || widget.activeSubscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجل الحضور متاح للعرض فقط لأن الاشتراك الحالي غير يومي'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final today = AppDateUtils.startOfDay(DateTime.now());
    final picked = AppDateUtils.startOfDay(selectedDay);

    if (picked.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن تسجيل الحضور لتاريخ مستقبلي'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await context.read<AttendanceCubit>().toggleAttendance(
      memberId: widget.memberId,
      subscriptionId: widget.activeSubscriptionId!,
      date: picked,
    );

    if (mounted) {
      widget.onAttendanceChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final attendedDates = state.attendedDates;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner if not interactive
            if (!widget.isDailyPlanActive) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'الاشتراك الحالي غير يومي — سجل الحضور متاح للعرض فقط',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'اضغط على أي يوم حتى تاريخ اليوم لتسجيل أو إلغاء الحضور',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Stats / Legend Card
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'إجمالي أيام الحضور: ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${attendedDates.length} يوم',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'حاضر',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Calendar Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: TableCalendar(
                locale: 'ar',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                startingDayOfWeek: StartingDayOfWeek.saturday,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'شهر',
                },
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextFormatter: (date, locale) =>
                      AppDateUtils.formatMonthYear(date),
                  titleTextStyle: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textPrimary,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendStyle: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: true,
                ),
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  _onDaySelected(selectedDay, attendedDates);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final attended = _isAttended(day, attendedDates);
                    if (attended) {
                      return _buildAttendedCell(day);
                    }
                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final attended = _isAttended(day, attendedDates);
                    return _buildTodayCell(day, attended);
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    final attended = _isAttended(day, attendedDates);
                    if (attended) {
                      return _buildAttendedCell(day, isOutside: true);
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttendedCell(DateTime day, {bool isOutside = false}) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isOutside
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: isOutside
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const Icon(
              Icons.check_rounded,
              size: 10,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCell(DateTime day, bool attended) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: attended ? AppColors.primary : AppColors.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: AppTextStyles.bodySmall.copyWith(
                color: attended ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            if (attended)
              const Icon(
                Icons.check_rounded,
                size: 10,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}
