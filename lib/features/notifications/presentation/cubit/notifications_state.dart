import 'package:equatable/equatable.dart';
import '../../../members/domain/entities/member_summary.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<MemberSummary> expiringSoon;
  final List<MemberSummary> expired;

  const NotificationsLoaded({
    required this.expiringSoon,
    required this.expired,
  });

  int get totalCount => expiringSoon.length + expired.length;
  bool get hasNotifications => totalCount > 0;

  @override
  List<Object?> get props => [expiringSoon, expired];
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}
