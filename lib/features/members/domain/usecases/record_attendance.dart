import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import '../repositories/attendance_repository.dart';

class RecordAttendanceParams {
  final int memberId;
  final bool allowDuplicate;
  final DateTime? checkInTime;

  const RecordAttendanceParams({
    required this.memberId,
    this.allowDuplicate = false,
    this.checkInTime,
  });
}

class RecordAttendance implements UseCase<Unit, RecordAttendanceParams> {
  final AttendanceRepository repository;

  RecordAttendance(this.repository);

  @override
  Future<Either<Failure, Unit>> call(RecordAttendanceParams params) async {
    final alreadyCheckedIn = await repository.hasCheckedInToday(params.memberId);
    final hasCheckedIn = alreadyCheckedIn.getOrElse((_) => false);
    if (hasCheckedIn) {
      return const Left(
        DatabaseFailure('ALREADY_CHECKED_IN_TODAY'),
      );
    }

    return repository.recordAttendance(
      params.memberId,
      checkInTime: params.checkInTime,
    );
  }
}
