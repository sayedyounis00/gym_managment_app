# Revised plan: Backup and Export (no PIN, no biometric)

I removed the lock screen, login, PIN, fingerprint, auto-lock, `LockCubit`, recovery code and the `FLAG_SECURE` option. What's left is backup and restore, export, and a simple settings page.

## 1. Scope

| Requirement | Delivered as |
|---|---|
| Back up and restore data | Zip backup of the database and photos, restore behind a warning dialog |
| Export member data | CSV and PDF export through the system share sheet |

The app opens straight to the dashboard, as before.

## 2. Folder structure

```
lib/features/settings/
  domain/
    entities/        backup_info.dart
    repositories/    backup_repository.dart, export_repository.dart
    usecases/        create_backup, restore_backup, get_last_backup_info,
                     export_members_csv, export_members_pdf
  data/
    datasources/     backup_source.dart (drift file + archive), export_source.dart
    repositories/    *_impl.dart
  presentation/
    cubit/           backup_cubit, export_cubit
    pages/           settings_page, backup_page, export_sheet
    widgets/         settings_group_card, backup_status_card
```

Use `Either<Failure, T>` from `fpdart` in the use cases and register them with `injectable`. You no longer need `local_auth` for this feature. `flutter_secure_storage` isn't needed either unless something else uses it. Keep `crypto` for the backup checksum.

## 3. Settings page

This follows design 7.5, reached from the gear in the Dashboard app bar, with grouped cards and 40×40 icon containers.

- **البيانات:** backup now, restore from backup, export members.
- **التنبيهات:** days before expiry, notification toggle (reusing the existing notification settings).
- **عن التطبيق:** version.

The الأمان group is gone.

## 4. Backup and restore

**Backup file:** `gym_backup_YYYYMMDD_HHmm.gymbak`, a zip made with `archive`, containing:
- `database.sqlite` (the drift file, copied after a WAL checkpoint so it is consistent)
- `photos/` (member photos)
- `manifest.json` with app version, schema version, created time, member count and a SHA-256 checksum of the database

**Create backup**
1. `BackupCubit` emits `inProgress`. The button shows its loading state and blocks taps.
2. Run the copy and zip off the UI thread with `compute`.
3. Save to app documents, then open the `share_plus` sheet or the `file_picker` save dialog so the owner can put the file in Drive, WhatsApp or on a USB drive. Keep the last 3 local copies.
4. Save the `last_backup_at` time and show a success snackbar with a leading `success` icon.

**Restore**
1. `file_picker` selects a `.gymbak` file.
2. Validate the zip, the manifest, the checksum and the schema version. Reject a newer schema than the app supports with a clear Arabic message. An older schema is migrated by drift.
3. Show the warning dialog "سيتم استبدال البيانات الحالية" with a Destructive confirm button, naming the backup's date and member count.
4. Take an automatic safety backup of the current data first.
5. Close the database, replace the file and photos, reopen it and rerun the migrations. If anything fails, roll back from the safety backup. Then re-seed the notification schedules.
6. Return to the dashboard and show a success banner.

**Auto-backup reminder (optional):** a weekly `workmanager` task writes a local backup silently. The dashboard shows a warning banner if the last backup is over 7 days old.

**Backup page UI**
- Status card with the last backup time and a `success` check, or a warning tint if there is none or it's stale.
- Primary button "نسخ احتياطي الآن".
- Outlined button "استعادة من نسخة".
- Danger zone card only if you add a reset-data feature.

## 5. Export members

- Entry points: Settings → البيانات, and the Members app bar `ios_share_rounded` action.
- A bottom sheet offers CSV or PDF, plus the status filter chips (الكل / نشط / ينتهي قريباً / منتهي / موقوف).
- **CSV:** use `csv` with a UTF-8 BOM so Excel shows Arabic correctly. Columns: name, phone, age, weight, height, gender, BMI, status, current package, start, end, outstanding balance.
- **PDF:** use `pdf` and `printing` with the bundled Cairo font and RTL direction. The table header uses `surfaceVariant` and bold `labelMedium`, with tabular figures.
- Write to a temp file and share it, so no storage permission is needed.
- Include private notes only if the owner ticks "تضمين الملاحظات" (off by default).

## 6. Design-system checklist

- Light theme only, colors from `AppColors`, no hardcoded hex.
- `EdgeInsetsDirectional` and `AlignmentDirectional` throughout.
- Buttons 52 high, radius 12, 16 bold, one primary per screen. Restore is Outlined and always behind a dialog.
- Touch targets are at least 48 dp, with Arabic `Semantics` labels on icon-only buttons.
- Loading uses `skeletonizer` for lists, the in-button spinner for actions, and a subtle liquid-glass loader for the full-screen backup and restore progress.
- Motion follows section 8 of `design.md`. Arabic labels use short verbs.

## 7. Testing

- **Unit:** manifest validation, checksum mismatch, CSV escaping with Arabic text and commas.
- **Integration:** backup, wipe, restore, then confirm that members, payments, subscriptions and photos match. Also test a corrupt file and a file from a newer schema.
- **Manual:** app killed mid-restore, RTL layout, large text.

## 8. Order of work

1. Backup source and `create_backup`.
2. Restore with validation, safety backup and rollback.
3. Settings and backup pages.
4. Export CSV, then PDF.
5. Tests, then the optional weekly reminder.

