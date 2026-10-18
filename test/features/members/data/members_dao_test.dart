import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/members_dao.dart';
import 'package:gym_managment_app/core/database/daos/notes_dao.dart';
import 'package:gym_managment_app/core/utils/arabic_search_utils.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';

void main() {
  late AppDatabase db;
  late MembersDao membersDao;
  late NotesDao notesDao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    membersDao = MembersDao(db);
    notesDao = NotesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MembersDao in-memory integration tests', () {
    test('insertMember and search with Arabic normalization', () async {
      final name = 'أحمد مُحَمَّد';
      final phone = '01012345678';
      final normName = ArabicSearchUtils.normalize(name);

      final id = await membersDao.insertMember(
        MembersCompanion.insert(
          name: name,
          phone: phone,
          searchName: Value(normName),
        ),
      );

      expect(id, isPositive);

      final member = await membersDao.getMemberById(id);
      expect(member, isNotNull);
      expect(member!.name, equals(name));
      expect(member.phone, equals(phone));

      // Test searching with normalized alef without hamza "احمد"
      final results1 = await membersDao.watchMembersWithStatus(query: 'احمد').first;
      expect(results1.length, equals(1));
      expect(results1.first.member.id, equals(id));

      // Test searching with partial phone
      final resultsPhone = await membersDao.watchMembersWithStatus(query: '010123').first;
      expect(resultsPhone.length, equals(1));
      expect(resultsPhone.first.member.id, equals(id));
    });

    test('watchMembersWithStatus accurately resolves derived status', () async {
      final now = DateTime.now();

      // Member 1: Active (subscription ends in 20 days)
      final m1 = await membersDao.insertMember(
        MembersCompanion.insert(name: 'عضو نشط', phone: '01000000001'),
      );
      await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m1,
          startDate: now.subtract(const Duration(days: 10)),
          endDate: now.add(const Duration(days: 20)),
        ),
      );

      // Member 2: Expiring soon (subscription ends in 3 days)
      final m2 = await membersDao.insertMember(
        MembersCompanion.insert(name: 'عضو سينتهي', phone: '01000000002'),
      );
      await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m2,
          startDate: now.subtract(const Duration(days: 27)),
          endDate: now.add(const Duration(days: 3)),
        ),
      );

      // Member 3: Expired (subscription ended yesterday)
      final m3 = await membersDao.insertMember(
        MembersCompanion.insert(name: 'عضو منتهي', phone: '01000000003'),
      );
      await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m3,
          startDate: now.subtract(const Duration(days: 40)),
          endDate: now.subtract(const Duration(days: 1)),
        ),
      );

      // Member 4: Suspended
      final m4 = await membersDao.insertMember(
        MembersCompanion.insert(
          name: 'عضو موقوف',
          phone: '01000000004',
          isSuspended: const Value(true),
        ),
      );

      // Verify all
      final all = await membersDao.watchMembersWithStatus().first;
      expect(all.length, equals(4));

      // Filter active
      final activeOnly = await membersDao
          .watchMembersWithStatus(statusFilter: MemberStatusType.active)
          .first;
      expect(activeOnly.length, equals(1));
      expect(activeOnly.first.member.id, equals(m1));

      // Filter expiringSoon
      final expiringOnly = await membersDao
          .watchMembersWithStatus(statusFilter: MemberStatusType.expiringSoon)
          .first;
      expect(expiringOnly.length, equals(1));
      expect(expiringOnly.first.member.id, equals(m2));

      // Filter expired
      final expiredOnly = await membersDao
          .watchMembersWithStatus(statusFilter: MemberStatusType.expired)
          .first;
      expect(expiredOnly.length, equals(1));
      expect(expiredOnly.first.member.id, equals(m3));

      // Filter paused
      final pausedOnly = await membersDao
          .watchMembersWithStatus(statusFilter: MemberStatusType.paused)
          .first;
      expect(pausedOnly.length, equals(1));
      expect(pausedOnly.first.member.id, equals(m4));
    });

    test('toggleSuspension updates isSuspended state', () async {
      final id = await membersDao.insertMember(
        MembersCompanion.insert(name: 'طارق', phone: '01222222222'),
      );

      await membersDao.toggleSuspension(id, true);
      final m = await membersDao.getMemberById(id);
      expect(m!.isSuspended, isTrue);

      await membersDao.toggleSuspension(id, false);
      final m2 = await membersDao.getMemberById(id);
      expect(m2!.isSuspended, isFalse);
    });

    test('deleteMember cascades notes', () async {
      final id = await membersDao.insertMember(
        MembersCompanion.insert(name: 'كريم', phone: '01555555555'),
      );

      await notesDao.insertNote(id, 'ملاحظة خاصة');

      final hasNotes = await notesDao.watchNotes(id).first;
      expect(hasNotes.length, equals(1));

      await membersDao.deleteMember(id);

      final deletedMember = await membersDao.getMemberById(id);
      expect(deletedMember, isNull);

      final remainingNotes = await notesDao.watchNotes(id).first;
      expect(remainingNotes.isEmpty, isTrue);
    });
  });

  group('NotesDao tests', () {
    test('Notes CRUD operations', () async {
      final mId = await membersDao.insertMember(
        MembersCompanion.insert(name: 'سارة', phone: '01111111111'),
      );

      final noteId = await notesDao.insertNote(mId, 'ملاحظة تدريبية');
      expect(noteId, isPositive);

      var list = await notesDao.watchNotes(mId).first;
      expect(list.length, equals(1));
      expect(list.first.note, equals('ملاحظة تدريبية'));

      await notesDao.updateNote(noteId, 'ملاحظة معدلة');
      list = await notesDao.watchNotes(mId).first;
      expect(list.first.note, equals('ملاحظة معدلة'));

      await notesDao.deleteNote(noteId);
      list = await notesDao.watchNotes(mId).first;
      expect(list.isEmpty, isTrue);
    });
  });
}
