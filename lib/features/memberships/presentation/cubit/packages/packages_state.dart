import 'package:equatable/equatable.dart';
import '../../../domain/entities/membership_package.dart';

abstract class PackagesState extends Equatable {
  const PackagesState();

  @override
  List<Object?> get props => [];
}

class PackagesInitial extends PackagesState {
  const PackagesInitial();
}

class PackagesLoading extends PackagesState {
  const PackagesLoading();
}

class PackagesLoaded extends PackagesState {
  final List<MembershipPackage> packages;

  const PackagesLoaded(this.packages);

  @override
  List<Object?> get props => [packages];
}

class PackagesEmpty extends PackagesState {
  const PackagesEmpty();
}

class PackagesError extends PackagesState {
  final String message;

  const PackagesError(this.message);

  @override
  List<Object?> get props => [message];
}
