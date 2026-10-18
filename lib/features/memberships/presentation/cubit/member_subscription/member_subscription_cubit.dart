import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/subscription.dart';
import '../../../domain/usecases/get_member_subscriptions.dart';
import 'member_subscription_state.dart';

class MemberSubscriptionCubit extends Cubit<MemberSubscriptionState> {
  final GetMemberSubscriptions getMemberSubscriptions;

  StreamSubscription? _currentSubSubscription;
  StreamSubscription? _historySubscription;

  Subscription? _cachedCurrent;
  List<Subscription> _cachedHistory = const [];

  MemberSubscriptionCubit({
    required this.getMemberSubscriptions,
  }) : super(const MemberSubscriptionInitial());

  void init(int memberId) {
    emit(const MemberSubscriptionLoading());

    _currentSubSubscription?.cancel();
    _historySubscription?.cancel();

    _currentSubSubscription = getMemberSubscriptions.watchCurrent(memberId).listen(
      (current) {
        _cachedCurrent = current;
        emit(MemberSubscriptionLoaded(
          currentSubscription: _cachedCurrent,
          history: _cachedHistory,
        ));
      },
      onError: (e) {
        emit(MemberSubscriptionError('تعذر استرجاع الاشتراك الحالي: $e'));
      },
    );

    _historySubscription = getMemberSubscriptions.watchHistory(memberId).listen(
      (history) {
        _cachedHistory = history;
        emit(MemberSubscriptionLoaded(
          currentSubscription: _cachedCurrent,
          history: _cachedHistory,
        ));
      },
      onError: (e) {
        emit(MemberSubscriptionError('تعذر استرجاع سجل الاشتراكات: $e'));
      },
    );
  }

  @override
  Future<void> close() {
    _currentSubSubscription?.cancel();
    _historySubscription?.cancel();
    return super.close();
  }
}
