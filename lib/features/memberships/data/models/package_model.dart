import 'package:drift/drift.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import '../../domain/entities/membership_package.dart';

class PackageModel {
  static MembershipPackage fromDrift(Package row) {
    return MembershipPackage(
      id: row.id,
      name: row.name,
      price: row.price,
      durationValue: row.durationValue,
      durationUnit: row.durationUnit,
      isActive: row.isActive,
      createdAt: row.createdAt,
    );
  }

  static PackagesCompanion toCompanion(MembershipPackage entity) {
    return PackagesCompanion(
      id: entity.id > 0 ? Value(entity.id) : const Value.absent(),
      name: Value(entity.name),
      price: Value(entity.price),
      durationValue: Value(entity.durationValue),
      durationUnit: Value(entity.durationUnit),
      durationInDays: Value(entity.estimatedDays),
      isActive: Value(entity.isActive),
      createdAt: Value(entity.createdAt),
    );
  }
}
