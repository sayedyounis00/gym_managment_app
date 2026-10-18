import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:gym_managment_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:gym_managment_app/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository mockRepository;
  late GetDashboardSummary useCase;

  setUp(() {
    mockRepository = MockDashboardRepository();
    useCase = GetDashboardSummary(mockRepository);
  });

  const testSummary = DashboardSummary(
    activeMembersCount: 15,
    newSubscriptionsThisMonth: 4,
    expiringSoon: [],
    monthRevenue: 2000.0,
    monthExpenses: 600.0,
    todayRevenue: 150.0,
  );

  test('returns DashboardSummary when repository call succeeds', () async {
    when(() => mockRepository.getSummary(now: any(named: 'now')))
        .thenAnswer((_) async => const Right(testSummary));

    final result = await useCase();

    expect(result, const Right(testSummary));
    verify(() => mockRepository.getSummary(now: any(named: 'now'))).called(1);
  });

  test('returns DatabaseFailure when repository call fails', () async {
    when(() => mockRepository.getSummary(now: any(named: 'now')))
        .thenAnswer((_) async => const Left(DatabaseFailure('Database error')));

    final result = await useCase();

    expect(result, const Left(DatabaseFailure('Database error')));
    verify(() => mockRepository.getSummary(now: any(named: 'now'))).called(1);
  });

  test('forwards watch stream from repository', () async {
    when(() => mockRepository.watchSummary(now: any(named: 'now')))
        .thenAnswer((_) => Stream.value(const Right(testSummary)));

    final stream = useCase.watch();

    expect(await stream.first, const Right(testSummary));
    verify(() => mockRepository.watchSummary(now: any(named: 'now'))).called(1);
  });
}
