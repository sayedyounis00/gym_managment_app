import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_packages.dart';
import '../../../domain/usecases/toggle_package_active.dart';
import 'packages_state.dart';

class PackagesCubit extends Cubit<PackagesState> {
  final GetPackages getPackages;
  final TogglePackageActive togglePackageActive;
  final DeletePackage deletePackage;

  StreamSubscription? _subscription;

  PackagesCubit({
    required this.getPackages,
    required this.togglePackageActive,
    required this.deletePackage,
  }) : super(const PackagesInitial());

  void init() {
    emit(const PackagesLoading());
    _subscription?.cancel();
    _subscription = getPackages.watch().listen(
      (packages) {
        if (packages.isEmpty) {
          emit(const PackagesEmpty());
        } else {
          emit(PackagesLoaded(packages));
        }
      },
      onError: (e) {
        emit(PackagesError('تعذر تحميل الباقات: $e'));
      },
    );
  }

  Future<void> toggleActive(int id, bool isActive) async {
    final result = await togglePackageActive(id, isActive);
    result.fold(
      (failure) => emit(PackagesError(failure.message)),
      (_) {},
    );
  }

  Future<bool> delete(int id) async {
    final result = await deletePackage(id);
    return result.fold(
      (failure) {
        emit(PackagesError(failure.message));
        return false;
      },
      (_) => true,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
