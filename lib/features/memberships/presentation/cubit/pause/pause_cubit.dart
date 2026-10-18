import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/memberships_repository.dart';
import '../../../domain/usecases/pause_subscription.dart';
import '../../../domain/usecases/resume_subscription.dart';
import 'pause_state.dart';

class PauseCubit extends Cubit<PauseState> {
  final PauseSubscription pauseSubscription;
  final ResumeSubscription resumeSubscription;

  PauseCubit({
    required this.pauseSubscription,
    required this.resumeSubscription,
  }) : super(PauseState(pauseDate: DateTime.now()));

  void init(int memberId) {
    emit(PauseState(
      memberId: memberId,
      pauseDate: DateTime.now(),
    ));
  }

  void setPauseDate(DateTime date) {
    emit(state.copyWith(
      pauseDate: date,
      clearErrorMessage: true,
    ));
  }

  void setReason(String? reason) {
    emit(state.copyWith(
      reason: reason,
      clearErrorMessage: true,
    ));
  }

  Future<bool> pause({
    required int memberId,
    required DateTime pauseDate,
    String? reason,
  }) async {
    emit(state.copyWith(
      isSubmitting: true,
      actionType: 'pause',
      clearErrorMessage: true,
    ));

    final result = await pauseSubscription(PauseParams(
      memberId: memberId,
      pauseDate: pauseDate,
      reason: reason,
    ));

    return result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
        ));
        return true;
      },
    );
  }

  Future<bool> resume({
    required int memberId,
    required DateTime resumeDate,
  }) async {
    emit(state.copyWith(
      isSubmitting: true,
      actionType: 'resume',
      clearErrorMessage: true,
    ));

    final result = await resumeSubscription(
      memberId: memberId,
      resumeDate: resumeDate,
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
        ));
        return true;
      },
    );
  }
}
