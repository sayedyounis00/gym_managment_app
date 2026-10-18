import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:gym_managment_app/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:gym_managment_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:gym_managment_app/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDashboardSummary extends Mock implements GetDashboardSummary {}

void main() {
  late MockGetDashboardSummary mockGetDashboardSummary;

  setUp(() {
    mockGetDashboardSummary = MockGetDashboardSummary();
  });

  const testSummary = DashboardSummary(
    activeMembersCount: 12,
    newSubscriptionsThisMonth: 3,
    expiringSoon: [],
    monthRevenue: 1200.0,
    monthExpenses: 400.0,
    todayRevenue: 50.0,
  );

  group('DashboardCubit', () {
    test('initial state is DashboardInitial', () {
      final cubit = DashboardCubit(getDashboardSummary: mockGetDashboardSummary);
      expect(cubit.state, const DashboardInitial());
      cubit.close();
    });

    blocTest<DashboardCubit, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when loadSummary succeeds',
      build: () {
        when(() => mockGetDashboardSummary(now: any(named: 'now')))
            .thenAnswer((_) async => const Right(testSummary));
        return DashboardCubit(getDashboardSummary: mockGetDashboardSummary);
      },
      act: (cubit) => cubit.loadSummary(),
      expect: () => [
        const DashboardLoading(),
        const DashboardLoaded(testSummary),
      ],
      verify: (_) {
        verify(() => mockGetDashboardSummary(now: any(named: 'now'))).called(1);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits [DashboardLoading, DashboardError] when loadSummary fails',
      build: () {
        when(() => mockGetDashboardSummary(now: any(named: 'now')))
            .thenAnswer((_) async => const Left(DatabaseFailure('Database error')));
        return DashboardCubit(getDashboardSummary: mockGetDashboardSummary);
      },
      act: (cubit) => cubit.loadSummary(),
      expect: () => [
        const DashboardLoading(),
        const DashboardError('Database error'),
      ],
      verify: (_) {
        verify(() => mockGetDashboardSummary(now: any(named: 'now'))).called(1);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits DashboardLoaded when refresh succeeds',
      build: () {
        when(() => mockGetDashboardSummary(now: any(named: 'now')))
            .thenAnswer((_) async => const Right(testSummary));
        return DashboardCubit(getDashboardSummary: mockGetDashboardSummary);
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        const DashboardLoaded(testSummary),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] on init and updates on stream events',
      build: () {
        when(() => mockGetDashboardSummary(now: any(named: 'now')))
            .thenAnswer((_) async => const Right(testSummary));
        when(() => mockGetDashboardSummary.watch(now: any(named: 'now')))
            .thenAnswer((_) => Stream.value(const Right(testSummary)));
        return DashboardCubit(getDashboardSummary: mockGetDashboardSummary);
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const DashboardLoading(),
        const DashboardLoaded(testSummary),
      ],
    );
  });
}
