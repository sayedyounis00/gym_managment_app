import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/membership_package.dart';
import '../../../domain/usecases/get_packages.dart';
import '../../../domain/usecases/save_package.dart';
import '../../../domain/usecases/toggle_package_active.dart';
import 'package_form_state.dart';

class PackageFormCubit extends Cubit<PackageFormState> {
  final SavePackage savePackage;
  final GetPackages getPackages;
  final DeletePackage deletePackage;

  PackageFormCubit({
    required this.savePackage,
    required this.getPackages,
    required this.deletePackage,
  }) : super(const PackageFormState());

  Future<void> init(int? packageId) async {
    if (packageId != null && packageId > 0) {
      emit(state.copyWith(isLoading: true));
      final result = await getPackages.getById(packageId);
      result.fold(
        (failure) => emit(state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        )),
        (pkg) => emit(PackageFormState(
          id: pkg.id,
          name: pkg.name,
          price: pkg.price,
          durationValue: pkg.durationValue,
          durationUnit: pkg.durationUnit,
          isActive: pkg.isActive,
          isPayAsYouGo: pkg.isPayAsYouGo,
          isLoading: false,
        )),
      );
    }
  }

  void setName(String name) {
    emit(state.copyWith(
      name: name,
      clearNameError: true,
      clearErrorMessage: true,
    ));
  }

  void setPrice(double price) {
    emit(state.copyWith(
      price: price,
      clearPriceError: true,
      clearErrorMessage: true,
    ));
  }

  void setDurationValue(int value) {
    emit(state.copyWith(
      durationValue: value,
      clearDurationError: true,
      clearErrorMessage: true,
    ));
  }

  void setDurationUnit(String unit) {
    emit(state.copyWith(
      durationUnit: unit,
      clearErrorMessage: true,
    ));
  }

  void setIsActive(bool isActive) {
    emit(state.copyWith(
      isActive: isActive,
      clearErrorMessage: true,
    ));
  }

  void setIsPayAsYouGo(bool isPayAsYouGo) {
    emit(state.copyWith(
      isPayAsYouGo: isPayAsYouGo,
      durationValue: isPayAsYouGo ? 1 : state.durationValue,
      durationUnit: isPayAsYouGo ? 'days' : state.durationUnit,
      clearErrorMessage: true,
      clearDurationError: true,
    ));
  }

  bool _validate() {
    String? nameError;
    String? priceError;
    String? durationError;

    if (state.name.trim().isEmpty) {
      nameError = 'اسم الباقة مطلوب';
    }
    if (state.price <= 0) {
      priceError = 'السعر يجب أن يكون أكبر من صفر';
    }
    if (!state.isPayAsYouGo && state.durationValue <= 0) {
      durationError = 'المدة يجب أن تكون يوماً واحداً على الأقل';
    }

    if (nameError != null || priceError != null || durationError != null) {
      emit(state.copyWith(
        nameError: nameError,
        priceError: priceError,
        durationError: durationError,
      ));
      return false;
    }

    return true;
  }

  Future<bool> save() async {
    if (!_validate()) return false;

    emit(state.copyWith(isSaving: true, clearErrorMessage: true));

    final package = MembershipPackage(
      id: state.id,
      name: state.name.trim(),
      price: state.price,
      durationValue: state.isPayAsYouGo ? 1 : state.durationValue,
      durationUnit: state.isPayAsYouGo ? 'days' : state.durationUnit,
      isActive: state.isActive,
      trackAttendance: state.isPayAsYouGo ? true : false,
      isPayAsYouGo: state.isPayAsYouGo,
      createdAt: DateTime.now(),
    );

    final result = await savePackage(package);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (newId) {
        emit(state.copyWith(
          isSaving: false,
          isSuccess: true,
        ));
        return true;
      },
    );
  }

  Future<String?> delete() async {
    if (state.id <= 0) return 'لا يمكن حذف باقة غير محفوظة';
    emit(state.copyWith(isSaving: true, clearErrorMessage: true));
    final result = await deletePackage(state.id);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          errorMessage: failure.message,
        ));
        return failure.message;
      },
      (_) {
        emit(state.copyWith(isSaving: false));
        return null;
      },
    );
  }
}
