import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';

sealed class MembersListState extends Equatable {
  const MembersListState();

  @override
  List<Object?> get props => [];
}

class MembersListInitial extends MembersListState {
  const MembersListInitial();
}

class MembersListLoading extends MembersListState {
  const MembersListLoading();
}

class MembersListLoaded extends MembersListState {
  final List<MemberSummary> members;
  final String query;
  final MemberStatusType? filter;
  final int totalCount;

  const MembersListLoaded({
    required this.members,
    this.query = '',
    this.filter,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [members, query, filter, totalCount];
}

class MembersListError extends MembersListState {
  final String message;

  const MembersListError(this.message);

  @override
  List<Object?> get props => [message];
}
