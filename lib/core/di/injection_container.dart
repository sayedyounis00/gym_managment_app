import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../database/app_database.dart';
import '../database/daos/dashboard_dao.dart';
import '../database/daos/members_dao.dart';
import '../database/daos/notes_dao.dart';
import '../services/image_storage_service.dart';
import '../services/notification_service.dart';

import '../../features/settings/data/datasources/backup_source.dart';
import '../../features/settings/data/datasources/export_source.dart';
import '../../features/settings/data/repositories/backup_repository_impl.dart';
import '../../features/settings/data/repositories/export_repository_impl.dart';
import '../../features/settings/domain/repositories/backup_repository.dart';
import '../../features/settings/domain/repositories/export_repository.dart';
import '../../features/settings/domain/usecases/create_backup.dart';
import '../../features/settings/domain/usecases/get_last_backup_info.dart';
import '../../features/settings/domain/usecases/restore_backup.dart';
import '../../features/settings/domain/usecases/export_members_csv.dart';
import '../../features/settings/domain/usecases/export_members_pdf.dart';
import '../../features/settings/presentation/cubit/backup_cubit.dart';
import '../../features/settings/presentation/cubit/export_cubit.dart';

import '../../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_summary.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';

import '../../features/members/data/repositories/members_repository_impl.dart';
import '../../features/members/data/repositories/notes_repository_impl.dart';
import '../../features/members/domain/repositories/members_repository.dart';
import '../../features/members/domain/repositories/notes_repository.dart';
import '../../features/members/domain/usecases/get_members.dart';
import '../../features/members/domain/usecases/get_member_details.dart';
import '../../features/members/domain/usecases/add_member.dart';
import '../../features/members/domain/usecases/update_member.dart';
import '../../features/members/domain/usecases/delete_member.dart';
import '../../features/members/domain/usecases/toggle_member_suspension.dart';
import '../../features/members/domain/usecases/record_payment.dart';
import '../../features/members/domain/usecases/notes_usecases.dart';
import '../../features/members/presentation/cubit/members_list/members_list_cubit.dart';
import '../../features/members/presentation/cubit/member_form/member_form_cubit.dart';
import '../../features/members/presentation/cubit/member_details/member_details_cubit.dart';
import '../../features/members/presentation/cubit/member_notes/member_notes_cubit.dart';

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
import '../../features/memberships/domain/usecases/delete_subscription.dart';
import '../../features/memberships/domain/usecases/schedule_expiry_notifications.dart';
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

  if (!sl.isRegistered<MembershipsDao>()) {
    sl.registerSingleton<MembershipsDao>(MembershipsDao(sl<AppDatabase>()));
  }

  // Services
  if (!sl.isRegistered<ImageStorageService>()) {
    sl.registerLazySingleton<ImageStorageService>(() => ImageStorageServiceImpl());
  }

  if (!sl.isRegistered<NotificationService>()) {
    sl.registerLazySingleton<NotificationService>(() => NotificationServiceImpl());
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

  if (!sl.isRegistered<RecordPayment>()) {
    sl.registerLazySingleton<RecordPayment>(
      () => RecordPayment(sl<MembersRepository>()),
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
        recordPaymentUseCase: sl<RecordPayment>(),
        deleteSubscriptionUseCase: sl<DeleteSubscription>(),
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

  if (!sl.isRegistered<DeleteSubscription>()) {
    sl.registerLazySingleton<DeleteSubscription>(() => DeleteSubscription(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<GetExpiringSubscriptions>()) {
    sl.registerLazySingleton<GetExpiringSubscriptions>(() => GetExpiringSubscriptions(sl<MembershipsRepository>()));
  }

  if (!sl.isRegistered<ScheduleExpiryNotifications>()) {
    sl.registerLazySingleton<ScheduleExpiryNotifications>(
      () => ScheduleExpiryNotifications(sl<NotificationService>()),
    );
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
        scheduleExpiryNotifications: sl<ScheduleExpiryNotifications>(),
      ),
    );
  }

  if (!sl.isRegistered<PauseCubit>()) {
    sl.registerFactory<PauseCubit>(
      () => PauseCubit(
        pauseSubscription: sl<PauseSubscription>(),
        resumeSubscription: sl<ResumeSubscription>(),
        scheduleExpiryNotifications: sl<ScheduleExpiryNotifications>(),
        getMemberSubscriptions: sl<GetMemberSubscriptions>(),
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

  // Storage
  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
  }

  // Settings & Backup
  if (!sl.isRegistered<BackupSource>()) {
    sl.registerLazySingleton<BackupSource>(
      () => BackupSourceImpl(
        db: sl<AppDatabase>(),
        secureStorage: sl<FlutterSecureStorage>(),
        notificationService: sl<NotificationService>(),
        onReinitializeDatabase: reinitializeDatabase,
      ),
    );
  }

  if (!sl.isRegistered<BackupRepository>()) {
    sl.registerLazySingleton<BackupRepository>(
      () => BackupRepositoryImpl(backupSource: sl<BackupSource>()),
    );
  }

  if (!sl.isRegistered<CreateBackup>()) {
    sl.registerLazySingleton<CreateBackup>(
      () => CreateBackup(sl<BackupRepository>()),
    );
  }

  if (!sl.isRegistered<RestoreBackup>()) {
    sl.registerLazySingleton<RestoreBackup>(
      () => RestoreBackup(sl<BackupRepository>()),
    );
  }

  if (!sl.isRegistered<GetLastBackupInfo>()) {
    sl.registerLazySingleton<GetLastBackupInfo>(
      () => GetLastBackupInfo(sl<BackupRepository>()),
    );
  }

  if (!sl.isRegistered<BackupCubit>()) {
    sl.registerFactory<BackupCubit>(
      () => BackupCubit(
        createBackupUseCase: sl<CreateBackup>(),
        restoreBackupUseCase: sl<RestoreBackup>(),
        getLastBackupInfoUseCase: sl<GetLastBackupInfo>(),
        backupRepository: sl<BackupRepository>(),
      ),
    );
  }

  // Settings & Export
  if (!sl.isRegistered<ExportSource>()) {
    sl.registerLazySingleton<ExportSource>(
      () => ExportSourceImpl(
        db: sl<AppDatabase>(),
        membersDao: sl<MembersDao>(),
      ),
    );
  }

  if (!sl.isRegistered<ExportRepository>()) {
    sl.registerLazySingleton<ExportRepository>(
      () => ExportRepositoryImpl(exportSource: sl<ExportSource>()),
    );
  }

  if (!sl.isRegistered<ExportMembersCsv>()) {
    sl.registerLazySingleton<ExportMembersCsv>(
      () => ExportMembersCsv(sl<ExportRepository>()),
    );
  }

  if (!sl.isRegistered<ExportMembersPdf>()) {
    sl.registerLazySingleton<ExportMembersPdf>(
      () => ExportMembersPdf(sl<ExportRepository>()),
    );
  }

  if (!sl.isRegistered<ExportCubit>()) {
    sl.registerFactory<ExportCubit>(
      () => ExportCubit(
        exportMembersCsv: sl<ExportMembersCsv>(),
        exportMembersPdf: sl<ExportMembersPdf>(),
      ),
    );
  }
}

Future<void> reinitializeDatabase() async {
  if (sl.isRegistered<AppDatabase>()) {
    try {
      await sl<AppDatabase>().close();
    } catch (_) {}
    await sl.unregister<AppDatabase>();
  }
  if (sl.isRegistered<DashboardDao>()) await sl.unregister<DashboardDao>();
  if (sl.isRegistered<MembersDao>()) await sl.unregister<MembersDao>();
  if (sl.isRegistered<NotesDao>()) await sl.unregister<NotesDao>();
  if (sl.isRegistered<MembershipsDao>()) await sl.unregister<MembershipsDao>();
  if (sl.isRegistered<DashboardLocalDataSource>()) await sl.unregister<DashboardLocalDataSource>();
  if (sl.isRegistered<DashboardRepository>()) await sl.unregister<DashboardRepository>();
  if (sl.isRegistered<MembersRepository>()) await sl.unregister<MembersRepository>();
  if (sl.isRegistered<NotesRepository>()) await sl.unregister<NotesRepository>();
  if (sl.isRegistered<MembershipsLocalDataSource>()) await sl.unregister<MembershipsLocalDataSource>();
  if (sl.isRegistered<MembershipsRepository>()) await sl.unregister<MembershipsRepository>();

  final newDb = AppDatabase();
  sl.registerSingleton<AppDatabase>(newDb);
  sl.registerSingleton<DashboardDao>(DashboardDao(newDb));
  sl.registerSingleton<MembersDao>(MembersDao(newDb));
  sl.registerSingleton<NotesDao>(NotesDao(newDb));
  sl.registerSingleton<MembershipsDao>(MembershipsDao(newDb));

  sl.registerLazySingleton<DashboardLocalDataSource>(
    () => DashboardLocalDataSourceImpl(dashboardDao: sl<DashboardDao>()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(localDataSource: sl<DashboardLocalDataSource>()),
  );
  sl.registerLazySingleton<MembersRepository>(
    () => MembersRepositoryImpl(
      membersDao: sl<MembersDao>(),
      notesDao: sl<NotesDao>(),
      imageStorageService: sl<ImageStorageService>(),
    ),
  );
  sl.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(notesDao: sl<NotesDao>()),
  );
  sl.registerLazySingleton<MembershipsLocalDataSource>(
    () => MembershipsLocalDataSourceImpl(dao: sl<MembershipsDao>()),
  );
  sl.registerLazySingleton<MembershipsRepository>(
    () => MembershipsRepositoryImpl(localDataSource: sl<MembershipsLocalDataSource>()),
  );

  // Trigger migration / opening by pinging database
  await newDb.customSelect('SELECT 1').get();
}

