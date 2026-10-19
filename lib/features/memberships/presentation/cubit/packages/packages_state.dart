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
  final bool hasMore;
  final bool isLoadingMore;
  final int totalCount;

  const PackagesLoaded(
    this.packages, {
    this.hasMore = false,
    this.isLoadingMore = false,
    int? totalCount,
  }) : totalCount = totalCount ?? packages.length;

  PackagesLoaded copyWith({
    List<MembershipPackage>? packages,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalCount,
  }) {
    return PackagesLoaded(
      packages ?? this.packages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [packages, hasMore, isLoadingMore, totalCount];
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
