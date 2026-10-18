import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/usecases/get_members.dart';
import 'members_list_state.dart';

class MembersListCubit extends Cubit<MembersListState> {
  final GetMembers getMembers;
  StreamSubscription? _subscription;
  Timer? _debounceTimer;

  String _currentQuery = '';
  MemberStatusType? _currentFilter;

  MembersListCubit({required this.getMembers}) : super(const MembersListInitial());

  void init({MemberStatusType? initialFilter}) {
    _currentFilter = initialFilter;
    _subscribe();
  }

  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _currentQuery = query.trim();
      _subscribe();
    });
  }

  void setFilter(MemberStatusType? filter) {
    _currentFilter = filter;
    _subscribe();
  }

  void refresh() {
    _subscribe();
  }

  void _subscribe() {
    emit(const MembersListLoading());
    _subscription?.cancel();

    _subscription = getMembers(
      GetMembersParams(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        statusFilter: _currentFilter,
      ),
    ).listen(
      (members) {
        emit(
          MembersListLoaded(
            members: members,
            query: _currentQuery,
            filter: _currentFilter,
            totalCount: members.length,
          ),
        );
      },
      onError: (e) {
        emit(MembersListError(e.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
