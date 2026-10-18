import 'package:equatable/equatable.dart';
import '../../../domain/entities/subscription.dart';

abstract class ExpiringState extends Equatable {
  const ExpiringState();

  @override
  List<Object?> get props => [];
}

class ExpiringInitial extends ExpiringState {
  const ExpiringInitial();
}

class ExpiringLoading extends ExpiringState {
  const ExpiringLoading();
}

class ExpiringLoaded extends ExpiringState {
  final List<Subscription> subscriptions;
  final int thresholdDays;

  const ExpiringLoaded({
    required this.subscriptions,
    this.thresholdDays = 3,
  });

  int get count => subscriptions.length;

  @override
  List<Object?> get props => [subscriptions, thresholdDays];
}

class ExpiringError extends ExpiringState {
  final String message;

  const ExpiringError(this.message);

  @override
  List<Object?> get props => [message];
}
