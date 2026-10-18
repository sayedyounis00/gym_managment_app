// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_dao.dart';

// ignore_for_file: type=lint
mixin _$PaymentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MembersTable get members => attachedDatabase.members;
  $PackagesTable get packages => attachedDatabase.packages;
  $SubscriptionsTable get subscriptions => attachedDatabase.subscriptions;
  $SubscriptionPeriodsTable get subscriptionPeriods =>
      attachedDatabase.subscriptionPeriods;
  $InstallmentsTable get installments => attachedDatabase.installments;
  $PaymentsTable get payments => attachedDatabase.payments;
  PaymentsDaoManager get managers => PaymentsDaoManager(this);
}

class PaymentsDaoManager {
  final _$PaymentsDaoMixin _db;
  PaymentsDaoManager(this._db);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$PackagesTableTableManager get packages =>
      $$PackagesTableTableManager(_db.attachedDatabase, _db.packages);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db.attachedDatabase, _db.subscriptions);
  $$SubscriptionPeriodsTableTableManager get subscriptionPeriods =>
      $$SubscriptionPeriodsTableTableManager(
        _db.attachedDatabase,
        _db.subscriptionPeriods,
      );
  $$InstallmentsTableTableManager get installments =>
      $$InstallmentsTableTableManager(_db.attachedDatabase, _db.installments);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
}
