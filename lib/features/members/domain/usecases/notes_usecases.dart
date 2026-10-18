import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import '../entities/member_note.dart';
import '../repositories/notes_repository.dart';

class GetMemberNotes {
  final NotesRepository repository;

  GetMemberNotes(this.repository);

  Stream<List<MemberNote>> call(int memberId) {
    return repository.watchNotes(memberId);
  }
}

class AddNoteParams {
  final int memberId;
  final String note;

  const AddNoteParams({required this.memberId, required this.note});
}

class AddNote implements UseCase<int, AddNoteParams> {
  final NotesRepository repository;

  AddNote(this.repository);

  @override
  Future<Either<Failure, int>> call(AddNoteParams params) {
    if (params.note.trim().isEmpty) {
      return Future.value(const Left(DatabaseFailure('نص الملاحظة فارغ')));
    }
    return repository.addNote(params.memberId, params.note);
  }
}

class UpdateNoteParams {
  final int noteId;
  final String note;

  const UpdateNoteParams({required this.noteId, required this.note});
}

class UpdateNote implements UseCase<Unit, UpdateNoteParams> {
  final NotesRepository repository;

  UpdateNote(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateNoteParams params) {
    if (params.note.trim().isEmpty) {
      return Future.value(const Left(DatabaseFailure('نص الملاحظة فارغ')));
    }
    return repository.updateNote(params.noteId, params.note);
  }
}

class DeleteNote implements UseCase<Unit, int> {
  final NotesRepository repository;

  DeleteNote(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int noteId) {
    return repository.deleteNote(noteId);
  }
}
