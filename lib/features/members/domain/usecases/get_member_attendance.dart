import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class GetMemberAttendanceParams {
  final int memberId;
  final DateTime month;

  const GetMemberAttendanceParams({
    required this.memberId,
    required this.month,
  });
}

class GetMemberAttendance {
  final AttendanceRepository repository;

  GetMemberAttendance(this.repository);

  Stream<List<AttendanceRecord>> call(GetMemberAttendanceParams params) {
    return repository.watchAttendance(params.memberId, params.month);
  }
}
