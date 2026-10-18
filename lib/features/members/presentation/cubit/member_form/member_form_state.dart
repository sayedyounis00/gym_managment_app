import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/features/members/domain/entities/gender.dart';

sealed class MemberFormState extends Equatable {
  const MemberFormState();

  @override
  List<Object?> get props => [];
}

class MemberFormInitial extends MemberFormState {
  const MemberFormInitial();
}

class MemberFormEditing extends MemberFormState {
  final int? memberId;
  final String name;
  final String phone;
  final Gender? gender;
  final String? existingPhotoPath;
  final File? newPhotoFile;
  final bool removeExistingPhoto;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? initialNote;
  final bool isSaving;
  final Map<String, String> errors;
  final bool isDirty;

  const MemberFormEditing({
    this.memberId,
    this.name = '',
    this.phone = '',
    this.gender,
    this.existingPhotoPath,
    this.newPhotoFile,
    this.removeExistingPhoto = false,
    this.age,
    this.weightKg,
    this.heightCm,
    this.initialNote,
    this.isSaving = false,
    this.errors = const {},
    this.isDirty = false,
  });

  bool get isEditMode => memberId != null;

  MemberFormEditing copyWith({
    int? memberId,
    String? name,
    String? phone,
    Gender? gender,
    String? existingPhotoPath,
    File? newPhotoFile,
    bool? removeExistingPhoto,
    int? age,
    double? weightKg,
    double? heightCm,
    String? initialNote,
    bool? isSaving,
    Map<String, String>? errors,
    bool? isDirty,
  }) {
    return MemberFormEditing(
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      existingPhotoPath: existingPhotoPath ?? this.existingPhotoPath,
      newPhotoFile: newPhotoFile ?? this.newPhotoFile,
      removeExistingPhoto: removeExistingPhoto ?? this.removeExistingPhoto,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      initialNote: initialNote ?? this.initialNote,
      isSaving: isSaving ?? this.isSaving,
      errors: errors ?? this.errors,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [
        memberId,
        name,
        phone,
        gender,
        existingPhotoPath,
        newPhotoFile,
        removeExistingPhoto,
        age,
        weightKg,
        heightCm,
        initialNote,
        isSaving,
        errors,
        isDirty,
      ];
}

class MemberFormSaved extends MemberFormState {
  final int memberId;
  final bool isEdit;

  const MemberFormSaved({required this.memberId, required this.isEdit});

  @override
  List<Object?> get props => [memberId, isEdit];
}

class MemberFormFailure extends MemberFormState {
  final String message;

  const MemberFormFailure(this.message);

  @override
  List<Object?> get props => [message];
}
