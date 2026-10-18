import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/features/members/domain/entities/attendance_record.dart';
import 'package:gym_managment_app/features/members/domain/repositories/attendance_repository.dart';
import 'package:gym_managment_app/features/members/domain/usecases/record_attendance.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  bool hasCheckedIn = false;
  int recordCount = 0;

  @override
  Stream<List<AttendanceRecord>> watchAttendance(int memberId, DateTime month) => const Stream.empty();

  @override
  Future<Either<Failure, bool>> hasCheckedInToday(int memberId) async => Right(hasCheckedIn);

  @override
  Future<Either<Failure, Unit>> recordAttendance(int memberId, {DateTime? checkInTime}) async {
    hasCheckedIn = true;
    recordCount++;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, int>> countTodayAttendance() async => Right(recordCount);
}

void main() {
  late FakeAttendanceRepository repository;
  late RecordAttendance useCase;

  setUp(() {
    repository = FakeAttendanceRepository();
    useCase = RecordAttendance(repository);
  });

  test('records attendance successfully when member has not checked in today', () async {
    final result = await useCase(const RecordAttendanceParams(memberId: 1));
    expect(result.isRight(), isTrue);
    expect(repository.recordCount, equals(1));
    expect(repository.hasCheckedIn, isTrue);
  });

  test('prevents duplicate attendance registration on the same day', () async {
    // First registration
    final firstResult = await useCase(const RecordAttendanceParams(memberId: 1));
    expect(firstResult.isRight(), isTrue);
    expect(repository.hasCheckedIn, isTrue);

    // Second registration attempt
    final secondResult = await useCase(const RecordAttendanceParams(memberId: 1));
    expect(secondResult.isLeft(), isTrue);
    secondResult.fold(
      (failure) => expect(failure.message, equals('ALREADY_CHECKED_IN_TODAY')),
      (_) => fail('Duplicate visit should be prevented'),
    );
    expect(repository.recordCount, equals(1));
  });
}
