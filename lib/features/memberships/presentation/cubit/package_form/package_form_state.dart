import 'package:equatable/equatable.dart';

class PackageFormState extends Equatable {
  final int id;
  final String name;
  final double price;
  final int durationValue;
  final String durationUnit; // 'days' | 'months'
  final bool isActive;
  final bool isLoading;
  final bool isSaving;
  final bool isSuccess;
  final String? errorMessage;
  final String? nameError;
  final String? priceError;
  final String? durationError;

  const PackageFormState({
    this.id = 0,
    this.name = '',
    this.price = 0.0,
    this.durationValue = 1,
    this.durationUnit = 'months',
    this.isActive = true,
    this.isLoading = false,
    this.isSaving = false,
    this.isSuccess = false,
    this.errorMessage,
    this.nameError,
    this.priceError,
    this.durationError,
  });

  bool get isEditMode => id > 0;

  PackageFormState copyWith({
    int? id,
    String? name,
    double? price,
    int? durationValue,
    String? durationUnit,
    bool? isActive,
    bool? isLoading,
    bool? isSaving,
    bool? isSuccess,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? nameError,
    bool clearNameError = false,
    String? priceError,
    bool clearPriceError = false,
    String? durationError,
    bool clearDurationError = false,
  }) {
    return PackageFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      priceError: clearPriceError ? null : (priceError ?? this.priceError),
      durationError: clearDurationError ? null : (durationError ?? this.durationError),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        durationValue,
        durationUnit,
        isActive,
        isLoading,
        isSaving,
        isSuccess,
        errorMessage,
        nameError,
        priceError,
        durationError,
      ];
}
