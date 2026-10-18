import 'package:equatable/equatable.dart';
import '../../../domain/entities/subscription.dart';

abstract class MemberSubscriptionState extends Equatable {
  const MemberSubscriptionState();

  @override
  List<Object?> get props => [];
}

class MemberSubscriptionInitial extends MemberSubscriptionState {
  const MemberSubscriptionInitial();
}

class MemberSubscriptionLoading extends MemberSubscriptionState {
  const MemberSubscriptionLoading();
}

class MemberSubscriptionLoaded extends MemberSubscriptionState {
  final Subscription? currentSubscription;
  final List<Subscription> history;

  const MemberSubscriptionLoaded({
    required this.currentSubscription,
    required this.history,
  });

  @override
  List<Object?> get props => [currentSubscription, history];
}

class MemberSubscriptionError extends MemberSubscriptionState {
  final String message;

  const MemberSubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}
