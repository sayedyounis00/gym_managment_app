import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/features/members/domain/usecases/get_member_details.dart';

sealed class MemberDetailsState extends Equatable {
  const MemberDetailsState();

  @override
  List<Object?> get props => [];
}

class MemberDetailsInitial extends MemberDetailsState {
  const MemberDetailsInitial();
}

class MemberDetailsLoading extends MemberDetailsState {
  const MemberDetailsLoading();
}

class MemberDetailsLoaded extends MemberDetailsState {
  final MemberDetailsData data;
  final bool isActionLoading;

  const MemberDetailsLoaded({
    required this.data,
    this.isActionLoading = false,
  });

  MemberDetailsLoaded copyWith({
    MemberDetailsData? data,
    bool? isActionLoading,
  }) {
    return MemberDetailsLoaded(
      data: data ?? this.data,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }

  @override
  List<Object?> get props => [data, isActionLoading];
}

class MemberDetailsError extends MemberDetailsState {
  final String message;

  const MemberDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

class MemberDeleted extends MemberDetailsState {
  const MemberDeleted();
}
