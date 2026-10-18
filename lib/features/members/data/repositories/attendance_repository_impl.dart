import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/database/daos/attendance_dao.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/features/members/domain/entities/attendance_record.dart';
import 'package:gym_managment_app/features/members/domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceDao attendanceDao;

  AttendanceRepositoryImpl({required this.attendanceDao});

  @override
  Stream<List<AttendanceRecord>> watchAttendance(int memberId, DateTime month) {
    return attendanceDao.watchAttendance(memberId, month).map((list) {
      return list.map((row) {
        return AttendanceRecord(
          id: row.id,
          memberId: row.memberId,
          checkInTime: row.checkInTime,
        );
      }).toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> recordAttendance(int memberId, {DateTime? checkInTime}) async {
    try {
      await attendanceDao.recordAttendance(memberId, checkInTime);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasCheckedInToday(int memberId) async {
    try {
      final checkedIn = await attendanceDao.hasCheckedInToday(memberId);
      return Right(checkedIn);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> countTodayAttendance() async {
    try {
      final count = await attendanceDao.countTodayAttendance();
      return Right(count);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
