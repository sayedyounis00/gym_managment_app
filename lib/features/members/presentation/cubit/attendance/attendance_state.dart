import 'package:equatable/equatable.dart';

class AttendanceState extends Equatable {
  final Set<DateTime> attendedDates;
  final bool isLoading;
  final String? errorMessage;

  const AttendanceState({
    this.attendedDates = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  AttendanceState copyWith({
    Set<DateTime>? attendedDates,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AttendanceState(
      attendedDates: attendedDates ?? this.attendedDates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [attendedDates, isLoading, errorMessage];
}
