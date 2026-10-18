import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchAttendance(int memberId, DateTime month);

  Future<Either<Failure, Unit>> recordAttendance(int memberId, {DateTime? checkInTime});

  Future<Either<Failure, bool>> hasCheckedInToday(int memberId);

  Future<Either<Failure, int>> countTodayAttendance();
}
