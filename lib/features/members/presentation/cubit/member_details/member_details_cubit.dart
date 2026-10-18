import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/features/members/domain/usecases/delete_member.dart';
import 'package:gym_managment_app/features/members/domain/usecases/get_member_details.dart';
import 'package:gym_managment_app/features/members/domain/usecases/toggle_member_suspension.dart';
import 'member_details_state.dart';

class MemberDetailsCubit extends Cubit<MemberDetailsState> {
  final GetMemberDetails getMemberDetails;
  final ToggleMemberSuspension toggleMemberSuspension;
  final DeleteMember deleteMember;

  int? _memberId;

  MemberDetailsCubit({
    required this.getMemberDetails,
    required this.toggleMemberSuspension,
    required this.deleteMember,
  }) : super(const MemberDetailsInitial());

  Future<void> load(int memberId) async {
    _memberId = memberId;
    emit(const MemberDetailsLoading());
    await _fetchData();
  }

  Future<void> refresh() async {
    if (_memberId == null) return;
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (_memberId == null) return;
    final result = await getMemberDetails(_memberId!);
    result.fold(
      (failure) => emit(MemberDetailsError(failure.message)),
      (data) => emit(MemberDetailsLoaded(data: data)),
    );
  }

  Future<void> toggleSuspension() async {
    final s = state;
    if (s is! MemberDetailsLoaded || _memberId == null) return;

    emit(s.copyWith(isActionLoading: true));
    final newSuspended = !s.data.member.isSuspended;

    final result = await toggleMemberSuspension(
      ToggleSuspensionParams(
        memberId: _memberId!,
        isSuspended: newSuspended,
      ),
    );

    await result.fold(
      (failure) async {
        emit(MemberDetailsError(failure.message));
      },
      (_) async {
        await _fetchData();
      },
    );
  }

  Future<void> delete() async {
    if (_memberId == null) return;
    final s = state;
    if (s is MemberDetailsLoaded) {
      emit(s.copyWith(isActionLoading: true));
    }

    final result = await deleteMember(_memberId!);
    result.fold(
      (failure) => emit(MemberDetailsError(failure.message)),
      (_) => emit(const MemberDeleted()),
    );
  }
}
