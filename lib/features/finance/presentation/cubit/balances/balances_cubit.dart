import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/core/utils/arabic_search_utils.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/get_members_with_balance.dart';
import 'balances_state.dart';

class BalancesCubit extends Cubit<BalancesState> {
  final GetMembersWithBalance getMembersWithBalanceUseCase;

  BalancesCubit({required this.getMembersWithBalanceUseCase})
      : super(const BalancesInitial());

  Future<void> load() async {
    emit(const BalancesLoading());
    final result = await getMembersWithBalanceUseCase();
    result.fold(
      (failure) => emit(BalancesError(failure.message)),
      (balances) {
        if (balances.isEmpty) {
          emit(const BalancesEmpty());
        } else {
          emit(BalancesLoaded(
            allBalances: balances,
            filteredBalances: balances,
          ));
        }
      },
    );
  }

  void search(String query) {
    final s = state;
    if (s is! BalancesLoaded) return;

    if (query.trim().isEmpty) {
      emit(BalancesLoaded(
        allBalances: s.allBalances,
        filteredBalances: s.allBalances,
        searchQuery: '',
      ));
      return;
    }

    final normalizedQuery = ArabicSearchUtils.normalize(query);
    final normalizedPhoneQuery = ArabicSearchUtils.normalizePhone(query);

    final filtered = s.allBalances.where((b) {
      final nameMatches = ArabicSearchUtils.normalize(b.memberName).contains(normalizedQuery);
      final phoneMatches = normalizedPhoneQuery.isNotEmpty &&
          ArabicSearchUtils.normalizePhone(b.memberPhone).contains(normalizedPhoneQuery);
      return nameMatches || phoneMatches;
    }).toList();

    emit(BalancesLoaded(
      allBalances: s.allBalances,
      filteredBalances: filtered,
      searchQuery: query,
    ));
  }
}
