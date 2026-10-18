import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/database/daos/notes_dao.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_note.dart';
import 'package:gym_managment_app/features/members/domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesDao notesDao;

  NotesRepositoryImpl({required this.notesDao});

  @override
  Stream<List<MemberNote>> watchNotes(int memberId) {
    return notesDao.watchNotes(memberId).map((list) {
      return list.map((row) {
        return MemberNote(
          id: row.id,
          memberId: row.memberId,
          note: row.note,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        );
      }).toList();
    });
  }

  @override
  Future<Either<Failure, int>> addNote(int memberId, String text) async {
    try {
      final id = await notesDao.insertNote(memberId, text.trim());
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateNote(int id, String text) async {
    try {
      await notesDao.updateNote(id, text.trim());
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteNote(int id) async {
    try {
      await notesDao.deleteNote(id);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
