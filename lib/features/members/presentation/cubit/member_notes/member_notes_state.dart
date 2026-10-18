import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_note.dart';

sealed class MemberNotesState extends Equatable {
  const MemberNotesState();

  @override
  List<Object?> get props => [];
}

class MemberNotesInitial extends MemberNotesState {
  const MemberNotesInitial();
}

class MemberNotesLoading extends MemberNotesState {
  const MemberNotesLoading();
}

class MemberNotesLoaded extends MemberNotesState {
  final List<MemberNote> notes;
  final bool isSubmitting;

  const MemberNotesLoaded({
    required this.notes,
    this.isSubmitting = false,
  });

  MemberNotesLoaded copyWith({
    List<MemberNote>? notes,
    bool? isSubmitting,
  }) {
    return MemberNotesLoaded(
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [notes, isSubmitting];
}

class MemberNotesError extends MemberNotesState {
  final String message;

  const MemberNotesError(this.message);

  @override
  List<Object?> get props => [message];
}
