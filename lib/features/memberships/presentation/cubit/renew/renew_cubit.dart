import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import '../../../domain/entities/membership_package.dart';
import '../../../domain/repositories/memberships_repository.dart';
import '../../../domain/rules/membership_rules.dart';
import '../../../domain/usecases/get_member_subscriptions.dart';
import '../../../domain/usecases/get_packages.dart';
import '../../../domain/usecases/renew_subscription.dart';
import '../../../domain/usecases/schedule_expiry_notifications.dart';
import '../../../domain/entities/subscription.dart';
import 'renew_state.dart';

class RenewCubit extends Cubit<RenewState> {
  final RenewSubscription renewSubscription;
  final GetPackages getPackages;
  final GetMemberSubscriptions getMemberSubscriptions;
  final ScheduleExpiryNotifications? scheduleExpiryNotifications;

  RenewCubit({
    required this.renewSubscription,
    required this.getPackages,
    required this.getMemberSubscriptions,
    this.scheduleExpiryNotifications,
  }) : super(RenewState(
          startDate: AppDateUtils.startOfDay(DateTime.now()),
          endDate: AppDateUtils.startOfDay(DateTime.now().add(const Duration(days: 30))),
        ));

  Future<void> init({
    required int memberId,
    required String memberName,
    int? preselectedPackageId,
  }) async {
    emit(state.copyWith(
      isLoading: true,
      memberId: memberId,
      memberName: memberName,
      clearErrorMessage: true,
    ));

    // 1. Fetch active packages
    final packagesResult = await getPackages(activeOnly: true);
    final packages = packagesResult.getOrElse((_) => []);

    // 2. Fetch current member subscription to prefill
    final currentSubResult = await getMemberSubscriptions.getCurrent(memberId);
    final currentSub = currentSubResult.getOrElse((_) => null);

    // 3. Compute default start date
    final defaultStartDate = MembershipRules.calculateRenewStartDate(
      currentSubscription: currentSub,
      now: DateTime.now(),
    );

    // 4. Determine package to select
    MembershipPackage? selected;
    if (preselectedPackageId != null) {
      selected = packages.where((p) => p.id == preselectedPackageId).firstOrNull;
    }
    selected ??= (currentSub != null && currentSub.packageId != null)
        ? packages.where((p) => p.id == currentSub.packageId).firstOrNull
        : null;
    selected ??= packages.firstOrNull;

    // 5. Compute end date & default amount paid
    DateTime defaultEndDate;
    double defaultAmount = 0.0;
    if (selected != null) {
      defaultEndDate = MembershipRules.calculateEndDate(
        startDate: defaultStartDate,
        durationValue: selected.durationValue,
        durationUnit: selected.durationUnit,
      );
      defaultAmount = selected.price;
    } else {
      defaultEndDate = defaultStartDate.add(const Duration(days: 30));
    }

    emit(state.copyWith(
      isLoading: false,
      activePackages: packages,
      selectedPackage: selected,
      startDate: defaultStartDate,
      endDate: defaultEndDate,
      amountPaid: defaultAmount,
      previousSubscriptionId: currentSub?.id,
    ));
  }

  void selectPackage(MembershipPackage pkg) {
    final newEndDate = MembershipRules.calculateEndDate(
      startDate: state.startDate,
      durationValue: pkg.durationValue,
      durationUnit: pkg.durationUnit,
    );

    emit(state.copyWith(
      selectedPackage: pkg,
      endDate: newEndDate,
      amountPaid: pkg.price,
      clearErrorMessage: true,
    ));
  }

  void setStartDate(DateTime date) {
    DateTime newEndDate = date;
    if (state.selectedPackage != null) {
      newEndDate = MembershipRules.calculateEndDate(
        startDate: date,
        durationValue: state.selectedPackage!.durationValue,
        durationUnit: state.selectedPackage!.durationUnit,
      );
    } else {
      newEndDate = date.add(const Duration(days: 30));
    }

    emit(state.copyWith(
      startDate: date,
      endDate: newEndDate,
      clearErrorMessage: true,
    ));
  }

  void setAmountPaid(double amount) {
    emit(state.copyWith(
      amountPaid: amount,
      clearErrorMessage: true,
    ));
  }

  void setPaymentMethod(String method) {
    emit(state.copyWith(
      paymentMethod: method,
      clearErrorMessage: true,
    ));
  }

  Future<bool> submit() async {
    if (state.selectedPackage == null) {
      emit(state.copyWith(errorMessage: 'يرجى اختيار باقة'));
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final params = RenewParams(
      memberId: state.memberId,
      packageId: state.selectedPackage!.id,
      packageName: state.selectedPackage!.name,
      price: state.selectedPackage!.price,
      startDate: state.startDate,
      endDate: state.endDate,
      amountPaid: state.amountPaid,
      paymentMethod: state.paymentMethod,
      previousSubscriptionId: state.previousSubscriptionId,
    );

    final result = await renewSubscription(params);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (newSubId) {
        if (scheduleExpiryNotifications != null && state.selectedPackage != null) {
          scheduleExpiryNotifications!.scheduleForSubscription(
            subscription: Subscription(
              id: newSubId,
              memberId: state.memberId,
              packageId: state.selectedPackage!.id,
              packageNameSnapshot: state.selectedPackage!.name,
              priceSnapshot: state.selectedPackage!.price,
              startDate: state.startDate,
              endDate: state.endDate,
              status: 'active',
              amountPaid: state.amountPaid,
              createdAt: DateTime.now(),
            ),
            memberName: state.memberName,
          );
        }
        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          newSubscriptionId: newSubId,
        ));
        return true;
      },
    );
  }
}
