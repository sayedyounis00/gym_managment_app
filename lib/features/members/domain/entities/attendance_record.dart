import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  final int id;
  final int memberId;
  final DateTime checkInTime;

  const AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.checkInTime,
  });

  @override
  List<Object?> get props => [id, memberId, checkInTime];
}
