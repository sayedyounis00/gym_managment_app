import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/core/services/image_storage_service.dart';
import 'package:gym_managment_app/core/utils/arabic_search_utils.dart';
import 'package:gym_managment_app/core/utils/validators.dart';
import 'package:gym_managment_app/features/members/domain/entities/member.dart';
import 'package:gym_managment_app/features/members/domain/repositories/members_repository.dart';
import 'package:gym_managment_app/features/members/domain/usecases/add_member.dart';
import 'package:gym_managment_app/features/members/domain/usecases/update_member.dart';
import 'member_form_state.dart';

class MemberFormCubit extends Cubit<MemberFormState> {
  final MembersRepository membersRepository;
  final AddMember addMember;
  final UpdateMember updateMember;
  final ImageStorageService imageStorageService;

  MemberFormCubit({
    required this.membersRepository,
    required this.addMember,
    required this.updateMember,
    required this.imageStorageService,
  }) : super(const MemberFormInitial());

  Future<void> init([int? memberId]) async {
    if (memberId == null) {
      emit(const MemberFormEditing());
      return;
    }

    final result = await membersRepository.getMemberById(memberId);
    result.fold(
      (failure) => emit(MemberFormFailure(failure.message)),
      (member) {
        emit(
          MemberFormEditing(
            memberId: member.id,
            name: member.name,
            phone: member.phone,
            existingPhotoPath: member.photoPath,
            age: member.age,
            weightKg: member.weightKg,
            heightCm: member.heightCm,
            isDirty: false,
          ),
        );
      },
    );
  }

  void updateName(String name) {
    final s = state;
    if (s is! MemberFormEditing) return;
    final errors = Map<String, String>.from(s.errors)..remove('name');
    emit(s.copyWith(name: name, errors: errors, isDirty: true));
  }

  void updatePhone(String phone) {
    final s = state;
    if (s is! MemberFormEditing) return;
    final errors = Map<String, String>.from(s.errors)..remove('phone');
    emit(s.copyWith(phone: phone, errors: errors, isDirty: true));
  }

  void updateAge(String? ageStr) {
    final s = state;
    if (s is! MemberFormEditing) return;
    final errors = Map<String, String>.from(s.errors)..remove('age');
    final age = (ageStr != null && ageStr.trim().isNotEmpty)
        ? int.tryParse(ArabicSearchUtils.normalizePhone(ageStr))
        : null;
    emit(s.copyWith(age: age, errors: errors, isDirty: true));
  }

  void updateWeight(String? weightStr) {
    final s = state;
    if (s is! MemberFormEditing) return;
    final errors = Map<String, String>.from(s.errors)..remove('weight');
    final weight = (weightStr != null && weightStr.trim().isNotEmpty)
        ? double.tryParse(weightStr.trim())
        : null;
    emit(s.copyWith(weightKg: weight, errors: errors, isDirty: true));
  }

  void updateHeight(String? heightStr) {
    final s = state;
    if (s is! MemberFormEditing) return;
    final errors = Map<String, String>.from(s.errors)..remove('height');
    final height = (heightStr != null && heightStr.trim().isNotEmpty)
        ? double.tryParse(heightStr.trim())
        : null;
    emit(s.copyWith(heightCm: height, errors: errors, isDirty: true));
  }

  void updateInitialNote(String note) {
    final s = state;
    if (s is! MemberFormEditing) return;
    emit(s.copyWith(initialNote: note, isDirty: true));
  }

  void setPhoto(File file) {
    final s = state;
    if (s is! MemberFormEditing) return;
    emit(s.copyWith(newPhotoFile: file, removeExistingPhoto: false, isDirty: true));
  }

  void removePhoto() {
    final s = state;
    if (s is! MemberFormEditing) return;
    emit(
      s.copyWith(
        newPhotoFile: null,
        removeExistingPhoto: true,
        existingPhotoPath: null,
        isDirty: true,
      ),
    );
  }

  Future<void> save() async {
    final s = state;
    if (s is! MemberFormEditing || s.isSaving) return;

    final errors = <String, String>{};

    final nameErr = FormValidators.validateName(s.name);
    if (nameErr != null) errors['name'] = nameErr;

    final phoneErr = FormValidators.validatePhone(s.phone);
    if (phoneErr != null) errors['phone'] = phoneErr;

    if (s.age != null) {
      final ageErr = FormValidators.validateAge(s.age.toString());
      if (ageErr != null) errors['age'] = ageErr;
    }

    if (s.weightKg != null) {
      final weightErr = FormValidators.validateWeight(s.weightKg.toString());
      if (weightErr != null) errors['weight'] = weightErr;
    }

    if (s.heightCm != null) {
      final heightErr = FormValidators.validateHeight(s.heightCm.toString());
      if (heightErr != null) errors['height'] = heightErr;
    }

    if (errors.isNotEmpty) {
      emit(s.copyWith(errors: errors));
      return;
    }

    emit(s.copyWith(isSaving: true));

    try {
      String? photoPath = s.existingPhotoPath;

      if (s.memberId != null) {
        // Edit mode
        if (s.removeExistingPhoto && s.existingPhotoPath != null) {
          await imageStorageService.deletePhoto(s.existingPhotoPath!);
          photoPath = null;
        } else if (s.newPhotoFile != null) {
          photoPath = await imageStorageService.saveMemberPhoto(
            sourceFile: s.newPhotoFile!,
            memberId: s.memberId!,
            oldRelativePath: s.existingPhotoPath,
          );
        }

        final member = Member(
          id: s.memberId!,
          name: s.name.trim(),
          phone: s.phone.trim(),
          photoPath: photoPath,
          age: s.age,
          weightKg: s.weightKg,
          heightCm: s.heightCm,
          createdAt: DateTime.now(), // Ignored in update
          updatedAt: DateTime.now(),
        );

        final updateResult = await updateMember(member);
        updateResult.fold(
          (failure) => emit(s.copyWith(isSaving: false, errors: {'general': failure.message})),
          (_) => emit(MemberFormSaved(memberId: s.memberId!, isEdit: true)),
        );
      } else {
        // Create mode
        final addResult = await addMember(
          AddMemberParams(
            name: s.name.trim(),
            phone: s.phone.trim(),
            photoPath: null, // Will update with photo if present after ID generation
            age: s.age,
            weightKg: s.weightKg,
            heightCm: s.heightCm,
            initialNote: s.initialNote,
          ),
        );

        await addResult.fold(
          (failure) async {
            emit(s.copyWith(isSaving: false, errors: {'general': failure.message}));
          },
          (newId) async {
            if (s.newPhotoFile != null) {
              final newPhoto = await imageStorageService.saveMemberPhoto(
                sourceFile: s.newPhotoFile!,
                memberId: newId,
              );
              // Update member with photoPath
              final mResult = await membersRepository.getMemberById(newId);
              if (mResult.isRight()) {
                final member = mResult.getOrElse((_) => throw Exception());
                await updateMember(member.copyWith(photoPath: newPhoto));
              }
            }
            emit(MemberFormSaved(memberId: newId, isEdit: false));
          },
        );
      }
    } catch (e) {
      emit(s.copyWith(isSaving: false, errors: {'general': e.toString()}));
    }
  }
}
