import 'package:equatable/equatable.dart';

class MemberNote extends Equatable {
  final int id;
  final int memberId;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberNote({
    required this.id,
    required this.memberId,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, memberId, note, createdAt, updatedAt];
}
