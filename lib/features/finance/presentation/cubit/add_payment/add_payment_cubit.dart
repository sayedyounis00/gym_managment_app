import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/members_dao.dart';
import 'package:gym_managment_app/features/finance/domain/entities/finance_enums.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/add_payment.dart';
import 'add_payment_state.dart';

class AddPaymentCubit extends Cubit<AddPaymentState> {
  final AddPayment addPaymentUseCase;
  final MembersDao membersDao;
  final AppDatabase db;

  AddPaymentCubit({
    required this.addPaymentUseCase,
    required this.membersDao,
    required this.db,
  }) : super(AddPaymentState(paidAt: DateTime.now()));

  Future<void> init({int? preselectedMemberId}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final members = await db.select(db.members).get();

      emit(state.copyWith(
        isLoading: false,
        allMembers: members,
      ));

      if (preselectedMemberId != null) {
        await selectMember(preselectedMemberId);
      } else if (members.isNotEmpty) {
        await selectMember(members.first.id);
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> selectMember(int memberId) async {
    final member = state.allMembers.where((m) => m.id == memberId).firstOrNull ??
        await membersDao.getMemberById(memberId);

    // Fetch member's subscriptions & periods
    final memberSubs = await (db.select(db.subscriptions)
          ..where((s) => s.memberId.equals(memberId))
          ..orderBy([(s) => OrderingTerm.desc(s.startDate)]))
        .get();

    final List<MemberPeriodOption> options = [];

    for (final sub in memberSubs) {
      final periods = await (db.select(db.subscriptionPeriods)
            ..where((p) => p.subscriptionId.equals(sub.id))
            ..orderBy([(p) => OrderingTerm.asc(p.startDate)]))
          .get();

      final pkg = sub.packageId != null
          ? await (db.select(db.packages)..where((p) => p.id.equals(sub.packageId!))).getSingleOrNull()
          : null;
      final isPayAsYouGo = sub.isPayAsYouGo || (pkg?.isPayAsYouGo ?? false);

      if (isPayAsYouGo) {
        final countExpr = db.attendanceLogs.id.count();
        final q = db.selectOnly(db.attendanceLogs)
          ..addColumns([countExpr])
          ..where(db.attendanceLogs.subscriptionId.equals(sub.id));
        final attendedCount = await q.map((r) => r.read(countExpr)).getSingle() ?? 0;

        final dailyRate = sub.priceSnapshot ?? pkg?.price ?? 0.0;
        final due = attendedCount * dailyRate;

        final subPayments = await (db.select(db.payments)
              ..where((p) => p.subscriptionId.equals(sub.id) & p.voidedAt.isNull()))
            .get();
        final paid = subPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
        final remaining = (due - paid).clamp(0.0, double.infinity);

        final pkgName = sub.packageNameSnapshot ?? pkg?.name ?? 'اشتراك يومي';
        final label = attendedCount > 0 ? '$pkgName (حضور $attendedCount يوم)' : pkgName;

        options.add(MemberPeriodOption(
          subscriptionId: sub.id,
          periodId: null,
          label: label,
          dueAmount: due,
          paidAmount: paid,
          remaining: remaining,
          startDate: sub.startDate,
          isPayAsYouGo: true,
        ));
      } else if (periods.isNotEmpty) {
        for (final period in periods) {
          final periodPayments = await (db.select(db.payments)
                ..where((p) => p.periodId.equals(period.id) & p.voidedAt.isNull()))
              .get();
          final paid = periodPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
          final due = period.amountDue - period.discount;
          final remaining = (due - paid).clamp(0.0, double.infinity);

          options.add(MemberPeriodOption(
            subscriptionId: sub.id,
            periodId: period.id,
            label: '${sub.packageNameSnapshot ?? pkg?.name ?? "باقة"} - شهر ${period.periodNumber}',
            dueAmount: due,
            paidAmount: paid,
            remaining: remaining,
            startDate: period.startDate,
            isPayAsYouGo: false,
          ));
        }
      } else {
        // Fallback for sub without periods
        final subPayments = await (db.select(db.payments)
              ..where((p) => p.subscriptionId.equals(sub.id) & p.voidedAt.isNull()))
            .get();
        final paid = subPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
        final due = sub.priceSnapshot ?? pkg?.price ?? 0.0;
        final remaining = (due - paid).clamp(0.0, double.infinity);

        options.add(MemberPeriodOption(
          subscriptionId: sub.id,
          periodId: null,
          label: sub.packageNameSnapshot ?? pkg?.name ?? 'اشتراك',
          dueAmount: due,
          paidAmount: paid,
          remaining: remaining,
          startDate: sub.startDate,
          isPayAsYouGo: false,
        ));
      }
    }

    // Default to the first unpaid period option
    final unpaidOption = options.where((o) => o.remaining > 0.01).firstOrNull ?? options.firstOrNull;
    final defaultAmount = unpaidOption != null && unpaidOption.remaining > 0
        ? unpaidOption.remaining
        : 0.0;

    emit(state.copyWith(
      selectedMemberId: memberId,
      selectedMemberName: member?.name,
      periodOptions: options,
      selectedPeriod: unpaidOption,
      amount: defaultAmount,
      clearError: true,
    ));
  }

  void selectPeriod(MemberPeriodOption? period) {
    final defaultAmount = period != null && period.remaining > 0
        ? period.remaining
        : state.amount;

    emit(state.copyWith(
      selectedPeriod: period,
      clearSelectedPeriod: period == null,
      amount: defaultAmount,
    ));
  }

  void setAmount(double amount) {
    emit(state.copyWith(amount: amount));
  }

  void setMethod(PaymentMethod? method) {
    emit(state.copyWith(method: method, clearMethod: method == null));
  }

  void setDate(DateTime date) {
    emit(state.copyWith(paidAt: date));
  }

  void setNote(String? note) {
    emit(state.copyWith(note: note));
  }

  Future<bool> submit() async {
    if (state.selectedMemberId == null) {
      emit(state.copyWith(errorMessage: 'يرجى اختيار المشترك'));
      return false;
    }

    if (state.amount <= 0) {
      emit(state.copyWith(errorMessage: 'يرجى إدخال مبلغ صحيح أكبر من صفر'));
      return false;
    }

    // Overpayment check per plan 6.2 (not applicable to Pay-As-You-Go which allows advance/any payment)
    if (state.selectedPeriod != null &&
        !state.selectedPeriod!.isPayAsYouGo &&
        state.selectedPeriod!.remaining > 0 &&
        state.amount > state.selectedPeriod!.remaining + 0.01) {
      emit(state.copyWith(
        errorMessage: 'المبلغ أكبر من المتبقي (${state.selectedPeriod!.remaining.toInt()} ج.م)',
      ));
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await addPaymentUseCase(
      AddPaymentParams(
        memberId: state.selectedMemberId!,
        subscriptionId: state.selectedPeriod?.subscriptionId,
        periodId: state.selectedPeriod?.periodId,
        amount: state.amount,
        method: state.method,
        paidAt: state.paidAt,
        note: state.note,
      ),
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (paymentId) {
        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
        ));
        return true;
      },
    );
  }
}
