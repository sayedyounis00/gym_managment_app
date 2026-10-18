import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../entities/member_note.dart';

abstract class NotesRepository {
  Stream<List<MemberNote>> watchNotes(int memberId);

  Future<Either<Failure, int>> addNote(int memberId, String text);

  Future<Either<Failure, Unit>> updateNote(int id, String text);

  Future<Either<Failure, Unit>> deleteNote(int id);
}
