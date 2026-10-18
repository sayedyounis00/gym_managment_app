import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/features/members/domain/entities/attendance_record.dart';

sealed class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

class AttendanceLoaded extends AttendanceState {
  final DateTime currentMonth;
  final List<DateTime> attendedDays;
  final List<AttendanceRecord> records;
  final bool hasCheckedInToday;
  final bool isCheckingIn;
  final String? successMessage;

  const AttendanceLoaded({
    required this.currentMonth,
    required this.attendedDays,
    required this.records,
    required this.hasCheckedInToday,
    this.isCheckingIn = false,
    this.successMessage,
  });

  AttendanceLoaded copyWith({
    DateTime? currentMonth,
    List<DateTime>? attendedDays,
    List<AttendanceRecord>? records,
    bool? hasCheckedInToday,
    bool? isCheckingIn,
    String? successMessage,
  }) {
    return AttendanceLoaded(
      currentMonth: currentMonth ?? this.currentMonth,
      attendedDays: attendedDays ?? this.attendedDays,
      records: records ?? this.records,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentMonth,
        attendedDays,
        records,
        hasCheckedInToday,
        isCheckingIn,
        successMessage,
      ];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}

class AttendanceDuplicateWarning extends AttendanceState {
  final int memberId;

  const AttendanceDuplicateWarning(this.memberId);

  @override
  List<Object?> get props => [memberId];
}
