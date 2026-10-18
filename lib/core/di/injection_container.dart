import 'package:get_it/get_it.dart';
import '../database/app_database.dart';
import '../database/daos/dashboard_dao.dart';
import '../database/daos/members_dao.dart';
import '../database/daos/notes_dao.dart';
import '../database/daos/attendance_dao.dart';
import '../services/image_storage_service.dart';

import '../../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_summary.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';

import '../../features/members/data/repositories/members_repository_impl.dart';
import '../../features/members/data/repositories/notes_repository_impl.dart';
import '../../features/members/data/repositories/attendance_repository_impl.dart';
import '../../features/members/domain/repositories/members_repository.dart';
import '../../features/members/domain/repositories/notes_repository.dart';
import '../../features/members/domain/repositories/attendance_repository.dart';
import '../../features/members/domain/usecases/get_members.dart';
import '../../features/members/domain/usecases/get_member_details.dart';
import '../../features/members/domain/usecases/add_member.dart';
import '../../features/members/domain/usecases/update_member.dart';
import '../../features/members/domain/usecases/delete_member.dart';
import '../../features/members/domain/usecases/toggle_member_suspension.dart';
import '../../features/members/domain/usecases/notes_usecases.dart';
import '../../features/members/domain/usecases/record_attendance.dart';
import '../../features/members/domain/usecases/get_member_attendance.dart';
import '../../features/members/presentation/cubit/members_list/members_list_cubit.dart';
import '../../features/members/presentation/cubit/member_form/member_form_cubit.dart';
import '../../features/members/presentation/cubit/member_details/member_details_cubit.dart';
import '../../features/members/presentation/cubit/member_notes/member_notes_cubit.dart';
import '../../features/members/presentation/cubit/attendance/attendance_cubit.dart';

import '../database/daos/memberships_dao.dart';
import '../../features/memberships/data/datasources/memberships_local_datasource.dart';
import '../../features/memberships/data/repositories/memberships_repository_impl.dart';
import '../../features/memberships/domain/repositories/memberships_repository.dart';
import '../../features/memberships/domain/usecases/get_packages.dart';
import '../../features/memberships/domain/usecases/save_package.dart';
import '../../features/memberships/domain/usecases/toggle_package_active.dart';
import '../../features/memberships/domain/usecases/renew_subscription.dart';
import '../../features/memberships/domain/usecases/pause_subscription.dart';
import '../../features/memberships/domain/usecases/resume_subscription.dart';
import '../../features/memberships/domain/usecases/get_member_subscriptions.dart';
import '../../features/memberships/presentation/cubit/packages/packages_cubit.dart';
import '../../features/memberships/presentation/cubit/package_form/package_form_cubit.dart';
import '../../features/memberships/presentation/cubit/renew/renew_cubit.dart';
import '../../features/memberships/presentation/cubit/pause/pause_cubit.dart';
import '../../features/memberships/presentation/cubit/member_subscription/member_subscription_cubit.dart';
import '../../features/memberships/presentation/cubit/expiring/expiring_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies({
  AppDatabase? database,
  bool clearExistingData = false,
}) async {
  // Database & DAOs
  final db = database ?? AppDatabase();
  if (database == null && clearExistingData) {
    // Wipe any lingering demo data persisted from previous builds
    await db.clearAllData();
  }

  if (!sl.isRegistered<AppDatabase>()) {
    sl.registerSingleton<AppDatabase>(db);
  }

  if (!sl.isRegistered<DashboardDao>()) {
    sl.registerSingleton<DashboardDao>(DashboardDao(sl<AppDatabase>()));
  }

  if (!sl.isRegistered<MembersDao>()) {
    sl.registerSingleton<MembersDao>(MembersDao(sl<AppDatabase>()));
  }

  if (!sl.isRegistered<NotesDao>()) {
    sl.registerSingleton<NotesDao>(NotesDao(sl<AppDatabase>()));
  }

  if (!sl.isRegistered<AttendanceDao>()) {
    sl.registerSingleton<AttendanceDao>(AttendanceDao(sl<AppDatabase>()));
  }

  if (!sl.isRegistered<MembershipsDao>()) {
    sl.registerSingleton<MembershipsDao>(MembershipsDao(sl<AppDatabase>()));
  }

  // Services
  if (!sl.isRegistered<ImageStorageService>()) {
    sl.registerLazySingleton<ImageStorageService>(() => ImageStorageServiceImpl());
  }

  // Dashboard Data sources & Repositories
  if (!sl.isRegistered<DashboardLocalDataSource>()) {
    sl.registerLazySingleton<DashboardLocalDataSource>(
      () => DashboardLocalDataSourceImpl(dashboardDao: sl<DashboardDao>()),
    );
  }

  if (!sl.isRegistered<DashboardRepository>()) {
    sl.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(localDataSource: sl<DashboardLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<GetDashboardSummary>()) {
    sl.registerLazySingleton<GetDashboardSummary>(
      () => GetDashboardSummary(sl<DashboardRepository>()),
    );
  }

  if (!sl.isRegistered<DashboardCubit>()) {
    sl.registerFactory<DashboardCubit>(
      () => DashboardCubit(getDashboardSummary: sl<GetDashboardSummary>()),
    );
  }

  // Members Repositories
  if (!sl.isRegistered<MembersRepository>()) {
    sl.registerLazySingleton<MembersRepository>(
      () => MembersRepositoryImpl(
        membersDao: sl<MembersDao>(),
        notesDao: sl<NotesDao>(),
        imageStorageService: sl<ImageStorageService>(),
      ),
    );
  }

  if (!sl.isRegistered<NotesRepository>()) {
    sl.registerLazySingleton<NotesRepository>(
      () => NotesRepositoryImpl(notesDao: sl<NotesDao>()),
    );
  }

  if (!sl.isRegistered<AttendanceRepository>()) {
    sl.registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(attendanceDao: sl<AttendanceDao>()),
    );
  }

  // Members Use Cases
  if (!sl.isRegistered<GetMembers>()) {
    sl.registerLazySingleton<GetMembers>(() => GetMembers(sl<MembersRepository>()));
  }

  if (!sl.isRegistered<GetMemberDetails>()) {
    sl.registerLazySingleton<GetMemberDetails>(() => GetMemberDetails(sl<MembersRepository>()));
  }

  if (!sl.isRegistered<AddMember>()) {
    sl.registerLazySingleton<AddMember>(() => AddMember(sl<MembersRepository>()));
  }

  if (!sl.isRegistered<UpdateMember>()) {
    sl.registerLazySingleton<UpdateMember>(() => UpdateMember(sl<MembersRepository>()));
  }

  if (!sl.isRegistered<DeleteMember>()) {
    sl.registerLazySingleton<DeleteMember>(() => DeleteMember(sl<MembersRepository>()));
  }

  if (!sl.isRegistered<ToggleMemberSuspension>()) {
    sl.registerLazySingleton<ToggleMemberSuspension>(
      () => ToggleMemberSuspension(sl<MembersRepository>()),
    );
  }

  if (!sl.isRegistered<GetMemberNotes>()) {
    sl.registerLazySingleton<GetMemberNotes>(() => GetMemberNotes(sl<NotesRepository>()));
  }

  if (!sl.isRegistered<AddNote>()) {
    sl.registerLazySingleton<AddNote>(() => AddNote(sl<NotesRepository>()));
  }

  if (!sl.isRegistered<UpdateNote>()) {
    sl.registerLazySingleton<UpdateNote>(() => UpdateNote(sl<NotesRepository>()));
  }

  if (!sl.isRegistered<DeleteNote>()) {
    sl.registerLazySingleton<DeleteNote>(() => DeleteNote(sl<NotesRepository>()));
  }

  if (!sl.isRegistered<RecordAttendance>()) {
    sl.registerLazySingleton<RecordAttendance>(
      () => RecordAttendance(sl<AttendanceRepository>()),
    );
  }

  if (!sl.isRegistered<GetMemberAttendance>()) {
    sl.registerLazySingleton<GetMemberAttendance>(
      () => GetMemberAttendance(sl<AttendanceRepository>()),
    );
  }

  // Members Cubits (Factory)
  if (!sl.isRegistered<MembersListCubit>()) {
    sl.registerFactory<MembersListCubit>(
      () => MembersListCubit(getMembers: sl<GetMembers>()),
    );
  }

  if (!sl.isRegistered<MemberFormCubit>()) {
    sl.registerFactory<MemberFormCubit>(
      () => MemberFormCubit(
        membersRepository: sl<MembersRepository>(),
        addMember: sl<AddMember>(),
        updateMember: sl<UpdateMember>(),
        imageStorageService: sl<ImageStorageService>(),
      ),
    );
  }

  if (!sl.isRegistered<MemberDetailsCubit>()) {
    sl.registerFactory<MemberDetailsCubit>(
      () => MemberDetailsCubit(
        getMemberDetails: sl<GetMemberDetails>(),
        toggleMemberSuspension: sl<ToggleMemberSuspension>(),
        deleteMember: sl<DeleteMember>(),
      ),
    );
  }

  if (!sl.isRegistered<MemberNotesCubit>()) {
    sl.registerFactory<MemberNotesCubit>(
      () => MemberNotesCubit(
        getMemberNotes: sl<GetMemberNotes>(),
        addNote: sl<AddNote>(),
        updateNote: sl<UpdateNote>(),
        deleteNote: sl<DeleteNote>(),
      ),
    );
  }

  if (!sl.isRegistered<AttendanceCubit>()) {
    sl.registerFactory<AttendanceCubit>(
      () => AttendanceCubit(
        getMemberAttendance: sl<GetMemberAttendance>(),
        recordAttendance: sl<RecordAttendance>(),
        attendanceRepository: sl<AttendanceRepository>(),
      ),
    );
  }

  // Memberships Repositories
  if (!sl.isRegistered<MembershipsLocalDataSource>()) {
    sl.registerLazySingleton<MembershipsLocalDataSource>(
      () => MembershipsLocalDataSourceImpl(dao: sl<MembershipsDao>()),
    );
  }

  if (!sl.isRegistered<MembershipsRepository>()) {
    sl.registerLazySingleton<MembershipsRepository>(
      () => MembershipsRepositoryImpl(localDataSource: sl<MembershipsLocalDataSource>()),
    );
  }

  // Memberships Use Cases
  if (!sl.isRegistered<GetPackages>()) {
    sl.registerLazySingleton<GetPackages>(() => GetPackages(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<SavePackage>()) {
    sl.registerLazySingleton<SavePackage>(() => SavePackage(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<TogglePackageActive>()) {
    sl.registerLazySingleton<TogglePackageActive>(() => TogglePackageActive(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<DeletePackage>()) {
    sl.registerLazySingleton<DeletePackage>(() => DeletePackage(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<RenewSubscription>()) {
    sl.registerLazySingleton<RenewSubscription>(() => RenewSubscription(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<PauseSubscription>()) {
    sl.registerLazySingleton<PauseSubscription>(() => PauseSubscription(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<ResumeSubscription>()) {
    sl.registerLazySingleton<ResumeSubscription>(() => ResumeSubscription(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<GetMemberSubscriptions>()) {
    sl.registerLazySingleton<GetMemberSubscriptions>(() => GetMemberSubscriptions(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<GetExpiringSubscriptions>()) {
    sl.registerLazySingleton<GetExpiringSubscriptions>(() => GetExpiringSubscriptions(sl<MembershipsRepository>()));
  }

  // Memberships Cubits (Factory)
  if (!sl.isRegistered<PackagesCubit>()) {
    sl.registerFactory<PackagesCubit>(
      () => PackagesCubit(
        getPackages: sl<GetPackages>(),
        togglePackageActive: sl<TogglePackageActive>(),
        deletePackage: sl<DeletePackage>(),
      ),
    );
  }

  if (!sl.isRegistered<PackageFormCubit>()) {
    sl.registerFactory<PackageFormCubit>(
      () => PackageFormCubit(
        savePackage: sl<SavePackage>(),
        getPackages: sl<GetPackages>(),
      ),
    );
  }

  if (!sl.isRegistered<RenewCubit>()) {
    sl.registerFactory<RenewCubit>(
      () => RenewCubit(
        renewSubscription: sl<RenewSubscription>(),
        getPackages: sl<GetPackages>(),
        getMemberSubscriptions: sl<GetMemberSubscriptions>(),
      ),
    );
  }

  if (!sl.isRegistered<PauseCubit>()) {
    sl.registerFactory<PauseCubit>(
      () => PauseCubit(
        pauseSubscription: sl<PauseSubscription>(),
        resumeSubscription: sl<ResumeSubscription>(),
      ),
    );
  }

  if (!sl.isRegistered<MemberSubscriptionCubit>()) {
    sl.registerFactory<MemberSubscriptionCubit>(
      () => MemberSubscriptionCubit(
        getMemberSubscriptions: sl<GetMemberSubscriptions>(),
      ),
    );
  }

  if (!sl.isRegistered<ExpiringCubit>()) {
    sl.registerFactory<ExpiringCubit>(
      () => ExpiringCubit(
        getExpiringSubscriptions: sl<GetExpiringSubscriptions>(),
      ),
    );
  }
}
