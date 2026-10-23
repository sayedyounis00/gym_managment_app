import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/app.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('GymApp smoke test', (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());
    await initDependencies(database: testDb);

    await tester.pumpWidget(const GymApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pumpAndSettle();

    expect(find.text('لوحة التحكم'), findsOneWidget);
    await testDb.close();
  });
}
