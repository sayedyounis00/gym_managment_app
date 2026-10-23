import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/gender.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';
import 'package:gym_managment_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:gym_managment_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:gym_managment_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationsCubit extends Mock implements NotificationsCubit {}

void main() {
  late MockNotificationsCubit mockCubit;

  setUp(() {
    mockCubit = MockNotificationsCubit();
  });

  final expiringMember = MemberSummary(
    id: 1,
    name: 'أحمد محمود',
    phone: '01012345678',
    gender: Gender.male,
    status: MemberStatusType.expiringSoon,
    daysLeft: 2,
    packageName: 'باقة شهرية',
    subscriptionEndDate: DateTime.now().add(const Duration(days: 2)),
  );

  final expiredMember = MemberSummary(
    id: 2,
    name: 'سارة علي',
    phone: '01098765432',
    gender: Gender.female,
    status: MemberStatusType.expired,
    daysLeft: -4,
    packageName: 'باقة سنوية',
    subscriptionEndDate: DateTime.now().subtract(const Duration(days: 4)),
  );

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<NotificationsCubit>.value(
        value: mockCubit,
        child: const NotificationsPage(),
      ),
    );
  }

  group('NotificationsPage Widget Tests', () {
    testWidgets('renders loading indicator when state is NotificationsLoading',
        (tester) async {
      when(() => mockCubit.state).thenReturn(const NotificationsLoading());
      when(() => mockCubit.stream).thenAnswer(
        (_) => const Stream<NotificationsState>.empty(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state when both tabs are empty',
        (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationsLoaded(expiringSoon: [], expired: []),
      );
      when(() => mockCubit.stream).thenAnswer(
        (_) => const Stream<NotificationsState>.empty(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('الإشعارات والتنبيهات'), findsOneWidget);
      expect(find.text('تنتهي قريباً (0)'), findsOneWidget);
      expect(find.text('منتهية حديثاً (0)'), findsOneWidget);
      expect(find.text('لا توجد اشتراكات تنتهي قريباً'), findsOneWidget);
    });

    testWidgets('renders cards and switches between tabs properly',
        (tester) async {
      when(() => mockCubit.state).thenReturn(
        NotificationsLoaded(
          expiringSoon: [expiringMember],
          expired: [expiredMember],
        ),
      );
      when(() => mockCubit.stream).thenAnswer(
        (_) => const Stream<NotificationsState>.empty(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // On Tab 1: Expiring Soon
      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('متبقي 2 أيام'), findsOneWidget);
      expect(find.text('تجديد'), findsOneWidget);

      // Switch to Tab 2: Already Expired
      await tester.tap(find.text('منتهية حديثاً (1)'));
      await tester.pumpAndSettle();

      expect(find.text('سارة علي'), findsOneWidget);
      expect(find.text('منتهي منذ 4 يوم'), findsOneWidget);
    });

    testWidgets('renders responsive grid on wide screen (tablet >= 600px)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockCubit.state).thenReturn(
        NotificationsLoaded(
          expiringSoon: [expiringMember],
          expired: [],
        ),
      );
      when(() => mockCubit.stream).thenAnswer(
        (_) => const Stream<NotificationsState>.empty(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('أحمد محمود'), findsOneWidget);
    });
  });
}
