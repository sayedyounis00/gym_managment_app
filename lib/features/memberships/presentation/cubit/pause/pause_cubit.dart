import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/memberships_repository.dart';
import '../../../domain/usecases/get_member_subscriptions.dart';
import '../../../domain/usecases/pause_subscription.dart';
import '../../../domain/usecases/resume_subscription.dart';
import '../../../domain/usecases/schedule_expiry_notifications.dart';
import 'pause_state.dart';

class PauseCubit extends Cubit<PauseState> {
  final PauseSubscription pauseSubscription;
  final ResumeSubscription resumeSubscription;
  final ScheduleExpiryNotifications? scheduleExpiryNotifications;
  final GetMemberSubscriptions? getMemberSubscriptions;

  PauseCubit({
    required this.pauseSubscription,
    required this.resumeSubscription,
    this.scheduleExpiryNotifications,
    this.getMemberSubscriptions,
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
      (_) async {
        if (scheduleExpiryNotifications != null &&
            getMemberSubscriptions != null) {
          final current = await getMemberSubscriptions!.getCurrent(memberId);
          current.fold((_) => null, (sub) {
            if (sub != null) {
              scheduleExpiryNotifications!.cancelForSubscription(sub.id);
            }
          });
        }

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
      (_) async {
        if (scheduleExpiryNotifications != null &&
            getMemberSubscriptions != null) {
          final current = await getMemberSubscriptions!.getCurrent(memberId);
          current.fold((_) => null, (sub) {
            if (sub != null) {
              scheduleExpiryNotifications!.scheduleForSubscription(
                subscription: sub,
                memberName: 'المشترك',
              );
            }
          });
        }

        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
        ));
        return true;
      },
    );
  }
}
