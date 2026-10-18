// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_dao.dart';

// ignore_for_file: type=lint
mixin _$AttendanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $MembersTable get members => attachedDatabase.members;
  $AttendanceTable get attendance => attachedDatabase.attendance;
  AttendanceDaoManager get managers => AttendanceDaoManager(this);
}

class AttendanceDaoManager {
  final _$AttendanceDaoMixin _db;
  AttendanceDaoManager(this._db);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$AttendanceTableTableManager get attendance =>
      $$AttendanceTableTableManager(_db.attachedDatabase, _db.attendance);
}
