import 'package:equatable/equatable.dart';
import '../../../domain/entities/member_balance.dart';

sealed class BalancesState extends Equatable {
  const BalancesState();

  @override
  List<Object?> get props => [];
}

final class BalancesInitial extends BalancesState {
  const BalancesInitial();
}

final class BalancesLoading extends BalancesState {
  const BalancesLoading();
}

final class BalancesLoaded extends BalancesState {
  final List<MemberBalance> allBalances;
  final List<MemberBalance> filteredBalances;
  final String searchQuery;

  const BalancesLoaded({
    required this.allBalances,
    required this.filteredBalances,
    this.searchQuery = '',
  });

  double get totalOutstanding =>
      allBalances.fold<double>(0.0, (sum, b) => sum + b.remaining);

  @override
  List<Object?> get props => [allBalances, filteredBalances, searchQuery];
}

final class BalancesEmpty extends BalancesState {
  const BalancesEmpty();
}

final class BalancesError extends BalancesState {
  final String message;

  const BalancesError(this.message);

  @override
  List<Object?> get props => [message];
}
