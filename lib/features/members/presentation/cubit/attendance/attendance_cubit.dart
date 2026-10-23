import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/core/database/daos/attendance_dao.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceDao attendanceDao;
  StreamSubscription<List<DateTime>>? _subscription;

  AttendanceCubit({required this.attendanceDao})
      : super(const AttendanceState(isLoading: true));

  void init(int memberId) {
    _subscription?.cancel();
    emit(state.copyWith(isLoading: true));
    _subscription = attendanceDao.watchMemberAttendanceDates(memberId).listen(
      (dates) {
        final normalized = dates.map(AppDateUtils.startOfDay).toSet();
        emit(state.copyWith(
          attendedDates: normalized,
          isLoading: false,
          errorMessage: null,
        ));
      },
      onError: (err) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: err.toString(),
        ));
      },
    );
  }

  Future<void> toggleAttendance({
    required int memberId,
    required int subscriptionId,
    required DateTime date,
  }) async {
    try {
      await attendanceDao.toggleAttendance(
        memberId: memberId,
        subscriptionId: subscriptionId,
        date: date,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
