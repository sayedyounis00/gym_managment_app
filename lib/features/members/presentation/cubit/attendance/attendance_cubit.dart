import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/features/members/domain/repositories/attendance_repository.dart';
import 'package:gym_managment_app/features/members/domain/usecases/get_member_attendance.dart';
import 'package:gym_managment_app/features/members/domain/usecases/record_attendance.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final GetMemberAttendance getMemberAttendance;
  final RecordAttendance recordAttendance;
  final AttendanceRepository attendanceRepository;

  StreamSubscription? _subscription;
  int? _memberId;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  AttendanceCubit({
    required this.getMemberAttendance,
    required this.recordAttendance,
    required this.attendanceRepository,
  }) : super(const AttendanceInitial());

  void init(int memberId, [DateTime? initialMonth]) {
    _memberId = memberId;
    if (initialMonth != null) {
      _currentMonth = DateTime(initialMonth.year, initialMonth.month, 1);
    } else {
      final now = DateTime.now();
      _currentMonth = DateTime(now.year, now.month, 1);
    }
    _subscribe();
  }

  void changeMonth(DateTime newMonth) {
    _currentMonth = DateTime(newMonth.year, newMonth.month, 1);
    _subscribe();
  }

  void previousMonth() {
    final prev = _currentMonth.month == 1
        ? DateTime(_currentMonth.year - 1, 12, 1)
        : DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    changeMonth(prev);
  }

  void nextMonth() {
    final next = _currentMonth.month == 12
        ? DateTime(_currentMonth.year + 1, 1, 1)
        : DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    changeMonth(next);
  }

  Future<void> checkIn() async {
    if (_memberId == null) return;
    final s = state;
    if (s is AttendanceLoaded) {
      if (s.hasCheckedInToday) {
        emit(AttendanceDuplicateWarning(_memberId!));
        emit(s.copyWith(isCheckingIn: false));
        return;
      }
      emit(s.copyWith(isCheckingIn: true, successMessage: null));
    }

    final result = await recordAttendance(
      RecordAttendanceParams(
        memberId: _memberId!,
      ),
    );

    result.fold(
      (failure) {
        if (failure.message == 'ALREADY_CHECKED_IN_TODAY') {
          emit(AttendanceDuplicateWarning(_memberId!));
          if (s is AttendanceLoaded) {
            emit(s.copyWith(isCheckingIn: false, hasCheckedInToday: true));
          }
        } else {
          emit(AttendanceError(failure.message));
        }
      },
      (_) async {
        // Refresh today check-in status
        final todayCheck = await attendanceRepository.hasCheckedInToday(_memberId!);
        final hasCheckedToday = todayCheck.getOrElse((_) => true);
        if (state is AttendanceLoaded) {
          final curr = state as AttendanceLoaded;
          emit(
            curr.copyWith(
              isCheckingIn: false,
              hasCheckedInToday: hasCheckedToday,
              successMessage: 'تم تسجيل الحضور بنجاح',
            ),
          );
        }
      },
    );
  }

  void _subscribe() async {
    if (_memberId == null) return;
    emit(const AttendanceLoading());
    _subscription?.cancel();

    final todayCheck = await attendanceRepository.hasCheckedInToday(_memberId!);
    final hasCheckedToday = todayCheck.getOrElse((_) => false);

    _subscription = getMemberAttendance(
      GetMemberAttendanceParams(
        memberId: _memberId!,
        month: _currentMonth,
      ),
    ).listen(
      (records) {
        final uniqueDays = records
            .map((r) => DateTime(r.checkInTime.year, r.checkInTime.month, r.checkInTime.day))
            .toSet()
            .toList();

        emit(
          AttendanceLoaded(
            currentMonth: _currentMonth,
            attendedDays: uniqueDays,
            records: records,
            hasCheckedInToday: hasCheckedToday,
          ),
        );
      },
      onError: (e) {
        emit(AttendanceError(e.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
