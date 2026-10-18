// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members_dao.dart';

// ignore_for_file: type=lint
mixin _$MembersDaoMixin on DatabaseAccessor<AppDatabase> {
  $MembersTable get members => attachedDatabase.members;
  $PackagesTable get packages => attachedDatabase.packages;
  $SubscriptionsTable get subscriptions => attachedDatabase.subscriptions;
  $PaymentsTable get payments => attachedDatabase.payments;
  $MemberNotesTable get memberNotes => attachedDatabase.memberNotes;
  MembersDaoManager get managers => MembersDaoManager(this);
}

class MembersDaoManager {
  final _$MembersDaoMixin _db;
  MembersDaoManager(this._db);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$PackagesTableTableManager get packages =>
      $$PackagesTableTableManager(_db.attachedDatabase, _db.packages);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db.attachedDatabase, _db.subscriptions);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
  $$MemberNotesTableTableManager get memberNotes =>
      $$MemberNotesTableTableManager(_db.attachedDatabase, _db.memberNotes);
}
