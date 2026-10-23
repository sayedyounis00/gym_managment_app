import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/attendance_dao.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'package:gym_managment_app/features/members/presentation/cubit/attendance/attendance_cubit.dart';
import 'package:gym_managment_app/features/members/presentation/widgets/attendance_calendar_tab.dart';
import 'package:drift/native.dart';

Widget _buildTestWidget({
  required AttendanceCubit cubit,
  required int memberId,
  required bool isDailyPlanActive,
  int? activeSubscriptionId,
}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: BlocProvider<AttendanceCubit>.value(
        value: cubit,
        child: SingleChildScrollView(
          child: AttendanceCalendarTab(
            memberId: memberId,
            isDailyPlanActive: isDailyPlanActive,
            activeSubscriptionId: activeSubscriptionId,
          ),
        ),
      ),
    ),
  );
}

void main() {
  late AppDatabase db;
  late AttendanceDao attendanceDao;
  late AttendanceCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    attendanceDao = AttendanceDao(db);
    cubit = AttendanceCubit(attendanceDao: attendanceDao);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  testWidgets('renders read-only banner when daily plan is NOT active', (tester) async {
    cubit.init(1);
    await tester.pumpWidget(
      _buildTestWidget(
        cubit: cubit,
        memberId: 1,
        isDailyPlanActive: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('الاشتراك الحالي غير يومي — سجل الحضور متاح للعرض فقط'),
      findsOneWidget,
    );
    expect(find.textContaining('إجمالي أيام الحضور:'), findsOneWidget);
  });

  testWidgets('renders interactive banner when daily plan IS active', (tester) async {
    cubit.init(1);
    await tester.pumpWidget(
      _buildTestWidget(
        cubit: cubit,
        memberId: 1,
        isDailyPlanActive: true,
        activeSubscriptionId: 10,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('اضغط على أي يوم حتى تاريخ اليوم لتسجيل أو إلغاء الحضور'),
      findsOneWidget,
    );
    expect(find.textContaining('إجمالي أيام الحضور:'), findsOneWidget);
  });

  testWidgets('displays month number before month name in calendar header', (tester) async {
    cubit.init(1);
    await tester.pumpWidget(
      _buildTestWidget(
        cubit: cubit,
        memberId: 1,
        isDailyPlanActive: true,
        activeSubscriptionId: 10,
      ),
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final expectedHeader = AppDateUtils.formatMonthYear(now);
    expect(find.text(expectedHeader), findsOneWidget);
  });
}
