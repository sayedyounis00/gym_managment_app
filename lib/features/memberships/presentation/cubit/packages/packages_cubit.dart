import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/membership_package.dart';
import '../../../domain/usecases/get_packages.dart';
import '../../../domain/usecases/toggle_package_active.dart';
import 'packages_state.dart';

class PackagesCubit extends Cubit<PackagesState> {
  final GetPackages getPackages;
  final TogglePackageActive togglePackageActive;
  final DeletePackage deletePackage;

  StreamSubscription? _subscription;

  static const int pageSize = 10;
  int _visibleCount = pageSize;
  List<MembershipPackage> _allPackages = [];
  bool _isLoadingMore = false;

  PackagesCubit({
    required this.getPackages,
    required this.togglePackageActive,
    required this.deletePackage,
  }) : super(const PackagesInitial());

  void init() {
    emit(const PackagesLoading());
    _visibleCount = pageSize;
    _subscription?.cancel();
    _subscription = getPackages.watch().listen(
      (packages) {
        _allPackages = packages;
        _isLoadingMore = false;
        _emitLoaded();
      },
      onError: (e) {
        emit(PackagesError('تعذر تحميل الباقات: $e'));
      },
    );
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    if (_visibleCount >= _allPackages.length) return;

    _isLoadingMore = true;
    _emitLoaded();

    await Future.delayed(const Duration(milliseconds: 200));

    _visibleCount += pageSize;
    _isLoadingMore = false;
    _emitLoaded();
  }

  void _emitLoaded() {
    if (_allPackages.isEmpty) {
      emit(const PackagesEmpty());
      return;
    }

    final visiblePackages = _allPackages.take(_visibleCount).toList();
    emit(
      PackagesLoaded(
        visiblePackages,
        hasMore: _visibleCount < _allPackages.length,
        isLoadingMore: _isLoadingMore,
        totalCount: _allPackages.length,
      ),
    );
  }

  Future<void> toggleActive(int id, bool isActive) async {
    final result = await togglePackageActive(id, isActive);
    result.fold(
      (failure) => emit(PackagesError(failure.message)),
      (_) {},
    );
  }

  Future<String?> delete(int id) async {
    final result = await deletePackage(id);
    return result.fold(
      (failure) => failure.message,
      (_) => null,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
