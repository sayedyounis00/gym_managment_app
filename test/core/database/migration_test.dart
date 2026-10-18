import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';

void main() {
  test('AppDatabase schema version is 5 and tables can be queried', () async {
    final db = AppDatabase(NativeDatabase.memory());

    expect(db.schemaVersion, 5);

    // Verify all tables and new columns can be queried
    final packages = await db.select(db.packages).get();
    expect(packages, isEmpty);

    final subscriptions = await db.select(db.subscriptions).get();
    expect(subscriptions, isEmpty);

    final periods = await db.select(db.subscriptionPeriods).get();
    expect(periods, isEmpty);

    final installments = await db.select(db.installments).get();
    expect(installments, isEmpty);

    await db.close();
  });
}

