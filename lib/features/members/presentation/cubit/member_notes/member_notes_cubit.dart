import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_managment_app/features/members/domain/usecases/notes_usecases.dart';
import 'member_notes_state.dart';

class MemberNotesCubit extends Cubit<MemberNotesState> {
  final GetMemberNotes getMemberNotes;
  final AddNote addNote;
  final UpdateNote updateNote;
  final DeleteNote deleteNote;

  StreamSubscription? _subscription;
  int? _memberId;

  MemberNotesCubit({
    required this.getMemberNotes,
    required this.addNote,
    required this.updateNote,
    required this.deleteNote,
  }) : super(const MemberNotesInitial());

  void init(int memberId) {
    _memberId = memberId;
    emit(const MemberNotesLoading());
    _subscription?.cancel();
    _subscription = getMemberNotes(memberId).listen(
      (notes) {
        emit(MemberNotesLoaded(notes: notes));
      },
      onError: (e) {
        emit(MemberNotesError(e.toString()));
      },
    );
  }

  Future<void> submitAddNote(String text) async {
    if (_memberId == null) return;
    final s = state;
    if (s is MemberNotesLoaded) {
      emit(s.copyWith(isSubmitting: true));
    }

    final result = await addNote(
      AddNoteParams(memberId: _memberId!, note: text),
    );

    result.fold(
      (failure) => emit(MemberNotesError(failure.message)),
      (_) {
        // Stream will automatically deliver updated list
      },
    );
  }

  Future<void> submitUpdateNote(int noteId, String text) async {
    final s = state;
    if (s is MemberNotesLoaded) {
      emit(s.copyWith(isSubmitting: true));
    }

    final result = await updateNote(
      UpdateNoteParams(noteId: noteId, note: text),
    );

    result.fold(
      (failure) => emit(MemberNotesError(failure.message)),
      (_) {
        // Stream will automatically deliver updated list
      },
    );
  }

  Future<void> submitDeleteNote(int noteId) async {
    final s = state;
    if (s is MemberNotesLoaded) {
      emit(s.copyWith(isSubmitting: true));
    }

    final result = await deleteNote(noteId);
    result.fold(
      (failure) => emit(MemberNotesError(failure.message)),
      (_) {
        // Stream will automatically deliver updated list
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
