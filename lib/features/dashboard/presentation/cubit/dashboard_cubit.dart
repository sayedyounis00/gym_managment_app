import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_summary.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardSummary getDashboardSummary;
  StreamSubscription? _subscription;

  DashboardCubit({required this.getDashboardSummary}) : super(const DashboardInitial());

  void init({DateTime? now}) {
    loadSummary(now: now);
    _subscribeToUpdates(now: now);
  }

  Future<void> loadSummary({DateTime? now}) async {
    emit(const DashboardLoading());
    final result = await getDashboardSummary(now: now);
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (summary) => emit(DashboardLoaded(summary)),
    );
  }

  void _subscribeToUpdates({DateTime? now}) {
    _subscription?.cancel();
    _subscription = getDashboardSummary.watch(now: now).listen((result) {
      result.fold(
        (failure) => emit(DashboardError(failure.message)),
        (summary) => emit(DashboardLoaded(summary)),
      );
    });
  }

  Future<void> refresh({DateTime? now}) async {
    final result = await getDashboardSummary(now: now);
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (summary) => emit(DashboardLoaded(summary)),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
