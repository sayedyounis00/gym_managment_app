// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memberships_dao.dart';

// ignore_for_file: type=lint
mixin _$MembershipsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PackagesTable get packages => attachedDatabase.packages;
  $MembersTable get members => attachedDatabase.members;
  $SubscriptionsTable get subscriptions => attachedDatabase.subscriptions;
  $PaymentsTable get payments => attachedDatabase.payments;
  MembershipsDaoManager get managers => MembershipsDaoManager(this);
}

class MembershipsDaoManager {
  final _$MembershipsDaoMixin _db;
  MembershipsDaoManager(this._db);
  $$PackagesTableTableManager get packages =>
      $$PackagesTableTableManager(_db.attachedDatabase, _db.packages);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db.attachedDatabase, _db.subscriptions);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
}
