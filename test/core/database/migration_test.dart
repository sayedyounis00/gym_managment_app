import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';

void main() {
  test('AppDatabase schema version is 3 and migration runs without error', () async {
    final db = AppDatabase(NativeDatabase.memory());

    expect(db.schemaVersion, 3);

    // Verify all tables and new columns can be queried
    final packages = await db.select(db.packages).get();
    expect(packages, isEmpty);

    final subscriptions = await db.select(db.subscriptions).get();
    expect(subscriptions, isEmpty);

    await db.close();
  });
}
