import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';
import 'package:gym_managment_app/features/members/domain/usecases/get_members.dart';
import 'members_list_state.dart';

class MembersListCubit extends Cubit<MembersListState> {
  final GetMembers getMembers;
  StreamSubscription? _subscription;
  Timer? _debounceTimer;

  String _currentQuery = '';
  MemberStatusType? _currentFilter;

  static const int pageSize = 10;
  int _visibleCount = pageSize;
  List<MemberSummary> _allMembers = [];
  bool _isLoadingMore = false;

  MembersListCubit({required this.getMembers}) : super(const MembersListInitial());

  void init({MemberStatusType? initialFilter}) {
    _currentFilter = initialFilter;
    _visibleCount = pageSize;
    _subscribe();
  }

  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _currentQuery = query.trim();
      _visibleCount = pageSize;
      _subscribe();
    });
  }

  void setFilter(MemberStatusType? filter) {
    _currentFilter = filter;
    _visibleCount = pageSize;
    _subscribe();
  }

  void refresh() {
    _visibleCount = pageSize;
    _subscribe();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    if (_visibleCount >= _allMembers.length) return;

    _isLoadingMore = true;
    _emitLoaded();

    await Future.delayed(const Duration(milliseconds: 200));

    _visibleCount += pageSize;
    _isLoadingMore = false;
    _emitLoaded();
  }

  void _emitLoaded() {
    final visibleMembers = _allMembers.take(_visibleCount).toList();
    emit(
      MembersListLoaded(
        members: visibleMembers,
        query: _currentQuery,
        filter: _currentFilter,
        totalCount: _allMembers.length,
        hasMore: _visibleCount < _allMembers.length,
        isLoadingMore: _isLoadingMore,
      ),
    );
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
        _allMembers = members;
        _isLoadingMore = false;
        _emitLoaded();
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
