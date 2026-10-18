import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/member_notes_table.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [MemberNotes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Stream<List<MemberNote>> watchNotes(int memberId) {
    return (select(memberNotes)
          ..where((n) => n.memberId.equals(memberId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }

  Future<int> insertNote(int memberId, String text) {
    final now = DateTime.now();
    return into(memberNotes).insert(
      MemberNotesCompanion.insert(
        memberId: memberId,
        note: text,
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> updateNote(int id, String text) {
    return (update(memberNotes)..where((n) => n.id.equals(id))).write(
      MemberNotesCompanion(
        note: Value(text),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((rows) => rows > 0);
  }

  Future<int> deleteNote(int id) {
    return (delete(memberNotes)..where((n) => n.id.equals(id))).go();
  }
}
