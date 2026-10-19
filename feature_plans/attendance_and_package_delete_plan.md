# Plan: Package Delete + Attendance Tracking (Calendar)

**Schema:** v7 -> v8 | **Stack:** Flutter, Drift, SQLite, Cubit, Material 3 (light, RTL)

---

## 1. Goals

1. The owner can **delete a package** when needed.
2. When **creating/editing a package**, the owner chooses whether it **tracks attendance**.
3. In the **member profile**, if the member's subscription is on a tracking package, an **Attendance calendar** appears. Tapping a day marks attendance, and the day is filled with an **orange circle**.
4. Packages that do **not** track attendance show **no calendar**.

---

## 2. Decisions and Assumptions (please confirm)

| #   | Decision                                                                                                                                                                                                                               | Why                                                                  |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1   | Calendar package: **`table_calendar`** (pub.dev). There is no official "google_calendar" widget package; `table_calendar` is the standard one and supports RTL, Arabic locale, and custom day builders (needed for the orange circle). | Fully customizable                                                   |
| 2   | Package delete is allowed **even if subscriptions use it**. Old subscriptions keep their name and price through the existing `packageNameSnapshot` / `priceSnapshot` columns.                                                          | `subscriptions.packageId` is already nullable                        |
| 3   | The "track attendance" flag is **copied into the subscription** (snapshot) when it is created or renewed.                                                                                                                              | Deleting or editing a package later never breaks a member's calendar |
| 4   | Attendance is stored **per subscription**, one record per day.                                                                                                                                                                         | Calendar can be limited to the subscription dates                    |
| 5   | Tap a day = attended (orange circle). Tap again = remove (with confirmation).                                                                                                                                                          | Simple, matches your description                                     |

---

## 3. Database Changes (schema v8)

### 3.1 `packages` table: add column
| Column | Type | Default | Notes |
|---|---|---|---|
| `trackAttendance` | BOOL | `false` | Set in package create/edit form |

### 3.2 `subscriptions` table: add column
| Column | Type | Default | Notes |
|---|---|---|---|
| `trackAttendance` | BOOL | `false` | Snapshot copied from the package on create/renew. Old rows = `false` |

### 3.3 New table `attendance_logs`
> **Important:** do NOT name it `attendance`. `AppDatabase.beforeOpen` and the v4->v5 migration run `DROP TABLE IF EXISTS attendance;` and would delete it on every app start.

| Column | Type | Nullable | Constraints |
|---|---|---|---|
| `id` | INTEGER | No | PK, auto-increment |
| `memberId` | INTEGER | No | FK `members(id)` **ON DELETE CASCADE** |
| `subscriptionId` | INTEGER | No | FK `subscriptions(id)` **ON DELETE CASCADE** |
| `attendedOn` | DATETIME | No | Date only (normalized to 00:00 local) |
| `createdAt` | DATETIME | No | Default now |

- **Unique constraint:** `(subscriptionId, attendedOn)` so a day can't be recorded twice.
- **Indexes:** `idx_attendance_logs_member_id`, `idx_attendance_logs_subscription_id`, `idx_attendance_logs_attended_on`.

### 3.4 Migration `v7 -> v8`
1. `ALTER TABLE packages ADD COLUMN track_attendance INTEGER NOT NULL DEFAULT 0`
2. `ALTER TABLE subscriptions ADD COLUMN track_attendance INTEGER NOT NULL DEFAULT 0`
3. `CREATE TABLE attendance_logs (...)` + unique constraint + indexes
4. Bump `schemaVersion` to `8`.
5. Update `beforeOpen` so the legacy `DROP TABLE IF EXISTS attendance` still targets only the old table.

### 3.5 Package deletion rules (DAO)
`MembershipsDao.deletePackage(int id)` in one transaction:
1. `UPDATE subscriptions SET packageId = NULL WHERE packageId = :id` (snapshots keep name and price).
2. `DELETE FROM packages WHERE id = :id`.

Remove or relax the current guard `MembershipsDao.hasSubscriptions` that blocks deletion. Keep it only to count affected subscriptions for the confirm dialog (`countSubscriptionsForPackage`).

### 3.6 Attendance DAO (new `AttendanceDao`)
- `watchAttendance(subscriptionId)` -> stream of attended dates.
- `markAttendance(memberId, subscriptionId, date)` -> insert (ignore if exists).
- `unmarkAttendance(subscriptionId, date)` -> delete.
- `countAttendance(subscriptionId)` -> total days.
- `countCheckInsToday()` -> for the dashboard "Today's check-ins" card (design.md section 7.1).

### 3.7 Existing DAO updates
- `MembershipsDao.atomicRenew(...)` and subscription creation: copy `package.trackAttendance` into `subscriptions.trackAttendance`.
- Package create/update methods: accept the new flag.
- Member delete / subscription delete: attendance rows go automatically through FK cascade (verify with `PRAGMA foreign_keys = ON`, already enabled).

---

## 4. UI Changes

### 4.1 Packages screen (الباقات)
- **Create/Edit package form:** add a switch row **"تتبع الحضور"** (with hint: "سيظهر تقويم الحضور في ملف المشترك"), using the app Switch theme (primary color).
- **Package card:** small badge with `how_to_reg_rounded` + "يتبع الحضور" when enabled.
- **Delete:** delete icon (or overflow menu) on each package card.
  - Confirm dialog names the package: **"حذف الباقة (اسم الباقة)؟"**
  - If subscriptions use it: body says "X اشتراكات تستخدم هذه الباقة وستبقى بياناتها كما هي".
  - Destructive button (design.md 6.1) + Cancel outlined.
  - Success snackbar after delete.
- Keep the existing **active/inactive** toggle as the softer alternative to deleting.

### 4.2 Member Details screen
- **Attendance tab (الحضور)** is shown **only if** the member's current subscription has `trackAttendance == true`. Otherwise the tab is hidden.
- **Calendar (`table_calendar`):**
  - Locale `ar`, RTL, week starts on Saturday.
  - `selectedDayPredicate` / `calendarBuilders.defaultBuilder`: attended days are drawn as a **filled orange circle** (`AppColors.primary`, white bold number). Today gets an orange outline ring.
  - Tap a day inside the subscription range (start date to end date):
    - Not attended -> mark attended (light haptic).
    - Attended -> confirmation, then remove.
  - Days outside the subscription range, and future days, are greyed out and not tappable.
  - If the subscription is **paused**, the calendar is read-only with a purple "موقوف" banner.
  - Header shows the month and chevrons; `headerStyle` uses `titleLarge`; no format button.
- **Summary row above the calendar:** "أيام الحضور: N" and "الأيام المتبقية: M".
- **History:** if the member has older tracked subscriptions, a small selector chip lets the owner switch which subscription's calendar is shown (default = current).
- **Empty state** when no attended days: "لم يتم تسجيل أي حضور بعد".

### 4.3 Optional, same data
- **Dashboard** "Today's check-ins" card uses `countCheckInsToday()`.
- **Quick action** "تسجيل حضور": pick a member whose subscription tracks attendance, mark today.

---

## 5. Code Structure (clean architecture)

```
lib/core/database/
  tables/attendance_logs_table.dart        (new)
  tables/packages_table.dart               (+ trackAttendance)
  tables/subscriptions_table.dart          (+ trackAttendance)
  daos/attendance_dao.dart                 (new)
  daos/memberships_dao.dart                (deletePackage, renew snapshot)
  app_database.dart                        (schema 8, migration, register table/DAO)
lib/features/memberships/
  presentation/ package form switch, package card badge, delete dialog
lib/features/members/
  presentation/ attendance_tab.dart, attendance_calendar.dart, attendance_cubit.dart
```
Run `dart run build_runner build --delete-conflicting-outputs` after table changes. Add `table_calendar` to `pubspec.yaml`.

---

## 6. Backup and Restore Impact
- `attendance_logs` lives in the same SQLite file, so it is included in `.gymbak` automatically.
- Manifest `schema_version` becomes `8`.
- Restoring an old v7 backup must run the v8 migration (already handled by Drift on open); test this explicitly.

---

## 7. Implementation Steps (in order)
1. Add `trackAttendance` to `packages` and `subscriptions`; create `attendance_logs`; write migration v8; regenerate Drift code.
2. Write `AttendanceDao`; update `MembershipsDao` (delete package, snapshot flag on renew/create).
3. Package form: attendance switch. Package card: badge and delete action with confirm dialog.
4. Member details: conditional Attendance tab and `table_calendar` with orange filled days, tap to mark/unmark.
5. Handle edge cases (paused, out of range, future days).
6. Optional: dashboard check-ins card and quick action.
7. Update `DATABASE.md` (new table, ERD, migration v8, enums) and design.md (attendance calendar style).

---

## 8. Test Checklist
- Migrate a v7 database with data to v8: nothing lost, new columns default to false.
- Create a package with tracking ON -> subscribe a member -> calendar appears; with OFF -> no calendar.
- Edit the package later (turn tracking OFF) -> existing subscriptions keep their original flag.
- Mark a day, refresh, mark again (no duplicate), unmark.
- Delete a package with active subscriptions: subscription remains, name and price still shown, calendar still works.
- Delete a member / subscription: attendance rows removed.
- Pause a subscription: calendar read-only. Resume: editable again.
- Backup and restore on both v7 and v8 files.
- RTL layout and Arabic month names; touch targets >= 48dp.

---

## 9. Open Questions
1. Confirm `table_calendar` is the package you mean.
2. Should the owner be able to mark attendance for **past days** (forgot to record), or only **today**? (Plan assumes past days within the subscription range are allowed.)
