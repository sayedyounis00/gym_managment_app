import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/empty_state.dart';
import 'package:gym_managment_app/core/widgets/loaders/package_card_skeleton.dart';
import 'package:gym_managment_app/features/memberships/domain/entities/membership_package.dart';
import 'package:gym_managment_app/features/memberships/presentation/cubit/packages/packages_cubit.dart';
import 'package:gym_managment_app/features/memberships/presentation/cubit/packages/packages_state.dart';
import 'package:gym_managment_app/features/memberships/presentation/pages/packages_page.dart';
import 'package:gym_managment_app/features/memberships/presentation/widgets/package_card.dart';

class FakePackagesCubit extends Cubit<PackagesState> implements PackagesCubit {
  FakePackagesCubit(super.initialState);

  int initCallCount = 0;
  int? toggledId;
  bool? toggledVal;
  int? deletedId;

  @override
  get getPackages => throw UnimplementedError();

  @override
  get togglePackageActive => throw UnimplementedError();

  @override
  get deletePackage => throw UnimplementedError();

  @override
  Future<void> init({bool activeOnly = false}) async {
    initCallCount++;
  }

  @override
  Future<void> toggleActive(int id, bool isActive) async {
    toggledId = id;
    toggledVal = isActive;
  }

  @override
  Future<bool> delete(int id) async {
    deletedId = id;
    return true;
  }

  @override
  Future<void> loadMore() async {}

  void setState(PackagesState state) => emit(state);
}

void main() {
  final testPackages = [
    MembershipPackage(
      id: 1,
      name: 'باقة شهرية',
      durationValue: 1,
      durationUnit: 'months',
      price: 350.0,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    MembershipPackage(
      id: 2,
      name: 'باقة سنوية',
      durationValue: 12,
      durationUnit: 'months',
      price: 3000.0,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  Widget buildTestPage({
    required FakePackagesCubit cubit,
    double width = 360,
  }) {
    return MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: width,
            height: 800,
            child: BlocProvider<PackagesCubit>.value(
              value: cubit,
              child: const PackagesPage(),
            ),
          ),
        ),
      ),
    );
  }

  group('PackagesPage Widget Tests', () {
    testWidgets('shows PackageListSkeleton when loading', (tester) async {
      final cubit = FakePackagesCubit(PackagesLoading());

      await tester.pumpWidget(buildTestPage(cubit: cubit));

      expect(find.byType(PackageListSkeleton), findsOneWidget);
      expect(cubit.initCallCount, 1);
    });

    testWidgets('shows EmptyState when packages list is empty', (tester) async {
      final cubit = FakePackagesCubit(const PackagesEmpty());

      await tester.pumpWidget(buildTestPage(cubit: cubit));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('لا توجد بااقات بعد'), findsOneWidget);
    });

    testWidgets('shows error view and retries on press', (tester) async {
      final cubit = FakePackagesCubit(const PackagesError('فشل الاتصال'));

      await tester.pumpWidget(buildTestPage(cubit: cubit));

      expect(find.text('حدث خطأ أثناء تحميل الباقات'), findsOneWidget);
      expect(find.text('فشل الاتصال'), findsOneWidget);

      final retryButton = find.text('إعادة المحاولة');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pump();

      // Initial init (1) + Retry tap (1) = 2
      expect(cubit.initCallCount, 2);
    });

    testWidgets('renders mobile ListView on small screens (<600dp)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = FakePackagesCubit(PackagesLoaded(testPackages));

      await tester.pumpWidget(buildTestPage(cubit: cubit, width: 360));

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(PackageCard), findsNWidgets(2));
      expect(find.text('باقة شهرية'), findsOneWidget);
      expect(find.text('باقة سنوية'), findsOneWidget);
    });

    testWidgets('renders GridView on tablet/desktop screens (>=600dp)', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = FakePackagesCubit(PackagesLoaded(testPackages));

      await tester.pumpWidget(buildTestPage(cubit: cubit, width: 800));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(PackageCard), findsNWidgets(2));
    });

    testWidgets('FAB is present with Arabic label', (tester) async {
      final cubit = FakePackagesCubit(PackagesLoaded(testPackages));

      await tester.pumpWidget(buildTestPage(cubit: cubit));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('إنشاء باقة'), findsOneWidget);
    });
  });
}
