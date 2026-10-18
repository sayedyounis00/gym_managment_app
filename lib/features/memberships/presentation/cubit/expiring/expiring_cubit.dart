import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_expiring_subscriptions.dart';
import 'expiring_state.dart';

class ExpiringCubit extends Cubit<ExpiringState> {
  final GetExpiringSubscriptions getExpiringSubscriptions;

  StreamSubscription? _subscription;

  ExpiringCubit({
    required this.getExpiringSubscriptions,
  }) : super(const ExpiringInitial());

  void init({int thresholdDays = 3}) {
    emit(const ExpiringLoading());
    _subscription?.cancel();

    _subscription = getExpiringSubscriptions.watch(
      now: DateTime.now(),
      windowDays: thresholdDays,
    ).listen(
      (list) {
        emit(ExpiringLoaded(
          subscriptions: list,
          thresholdDays: thresholdDays,
        ));
      },
      onError: (e) {
        emit(ExpiringError('تعذر تحميل الاشتراكات التي تنتهي قريباً: $e'));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
