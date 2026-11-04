import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/app.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/core/router/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:drift/native.dart';
import 'package:gym_managment_app/core/router/routes.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await initializeDateFormatting('ar', null);
    Intl.defaultLocale = 'ar';
  });

  testWidgets('GymApp smoke test', (WidgetTester tester) async {
    await sl.reset();
    final testDb = AppDatabase(NativeDatabase.memory());
    await initDependencies(database: testDb);

    final router = createAppRouter(initialLocation: AppRoutes.dashboard);
    await tester.pumpWidget(GymApp(router: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('لوحة التحكم'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await testDb.close();
  });
}
