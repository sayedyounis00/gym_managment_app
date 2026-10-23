import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../members/domain/entities/member_summary.dart';
import '../../../members/domain/repositories/members_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final MembersRepository membersRepository;
  StreamSubscription<List<MemberSummary>>? _subscription;

  NotificationsCubit({required this.membersRepository})
      : super(const NotificationsInitial());

  void init() {
    emit(const NotificationsLoading());
    _subscription?.cancel();
    _subscription = membersRepository.watchMembers().listen(
      (members) {
        final expiringSoon = members
            .where((m) => m.status == MemberStatusType.expiringSoon)
            .toList()
          ..sort((a, b) {
            final aDays = a.daysLeft ?? 999;
            final bDays = b.daysLeft ?? 999;
            return aDays.compareTo(bDays);
          });

        final expired = members
            .where((m) =>
                m.status == MemberStatusType.expired &&
                (m.daysLeft == null || m.daysLeft! >= -30))
            .toList()
          ..sort((a, b) {
            final aDays = a.daysLeft ?? -999;
            final bDays = b.daysLeft ?? -999;
            return bDays.compareTo(aDays);
          });

        emit(NotificationsLoaded(
          expiringSoon: expiringSoon,
          expired: expired,
        ));
      },
      onError: (e) {
        emit(NotificationsError('فشل تحميل الإشعارات: ${e.toString()}'));
      },
    );
  }

  void refresh() {
    init();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
