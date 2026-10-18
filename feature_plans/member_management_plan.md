# Member Management — Implementation Plan

**Stack:** Flutter (Material 3, light only, Arabic RTL) · Clean Architecture · Cubit (flutter_bloc) · drift · get_it/injectable · freezed · go_router · fpdart
**Source of truth for UI:** `design.md` (tokens, components, screens 7.2). No hardcoded colors/sizes — only `AppColors`, `AppSpacing`, `AppRadius`, theme text styles.

---

## 0. Scope (from spec §2)

1. Add member: name, phone, photo
2. Record age, weight, height
3. View current + previous membership history
4. Search by name or phone
5. Private notes per member
6. Status: Active / Expired / Suspended (design adds "Expiring soon" as a derived display state)
7. Attendance history per member

**Out of scope:** visit-based memberships / visit counting. All subscriptions are duration-based only.

**Dependencies on other modules (kept thin):** memberships (packages, subscriptions, pause/resume, renew) and finance (payments). Member Management owns the *member*, *notes*, *attendance*. It reads subscriptions/payments through repository interfaces so the modules stay decoupled.

---

## 1. Folder Structure

```
lib/features/members/
  domain/
    entities/        member.dart, member_note.dart, attendance_record.dart,
                     member_summary.dart (list row: member + current sub + status)
    enums/           member_status.dart  (active, expiringSoon, expired, paused)
    repositories/    members_repository.dart, notes_repository.dart,
                     attendance_repository.dart
    usecases/        add_member, update_member, delete_member, get_members (watch),
                     search_members, get_member_details, add_note, update_note,
                     delete_note, check_in, get_attendance (by month),
                     get_membership_history
  data/
    tables/          members_table.dart, member_notes_table.dart,
                     attendance_table.dart   (drift)
    daos/            members_dao.dart, notes_dao.dart, attendance_dao.dart
    models/          mappers (drift row <-> entity)
    repositories/    *_repository_impl.dart  (@LazySingleton(as: ...))
  presentation/
    cubit/           members_list_cubit, member_form_cubit, member_details_cubit,
                     member_notes_cubit, attendance_cubit
    pages/           members_page, member_form_page, member_details_page
    widgets/         member_tile, member_filter_bar, body_stats_card,
                     current_membership_card, attendance_calendar,
                     notes_tab, history_tab, photo_picker_sheet, ...
lib/core/widgets/    status_chip, empty_state, confirm_dialog, app_text_field,
                     app_button, stat_card   (shared, built once, reused)
```

---

## 2. Data Layer (drift)

### Tables
| Table | Columns |
|---|---|
| `members` | `id` (uuid, PK), `name`, `phone` (unique), `photoPath?`, `age?`, `weightKg?` (real), `heightCm?` (real), `isSuspended` (bool), `createdAt`, `updatedAt` |
| `member_notes` | `id`, `memberId` (FK, cascade), `text`, `createdAt`, `updatedAt` |
| `attendance` | `id`, `memberId` (FK, cascade), `checkedInAt` (datetime) |

- Index: `members(name)`, `members(phone)`, `attendance(memberId, checkedInAt)`.
- Phone stored normalized (digits only, Western digits, 11 digits for EG) → reliable search/uniqueness regardless of display digits.
- **Status is derived, not stored** (except `isSuspended`): computed from the latest subscription end date and the "days before expiry" setting. Avoids stale data.
- Migration: bump drift `schemaVersion`, write a `MigrationStrategy.onUpgrade` step; add a migration test.

### Queries (DAO)
- `watchMembers(query, statusFilter)` — joins members → latest subscription; returns `Stream<List<MemberSummary>>`. Search = `name LIKE %q% OR phone LIKE %q%`, with Arabic normalization (strip tashkeel, unify أ/إ/آ→ا, ى→ي, ة→ه) done in Dart on a stored `searchName` column, or via normalized query.
- `watchMemberById`, `watchNotes(memberId)`, `watchAttendance(memberId, month)`, `membershipHistory(memberId)` (reads subscriptions table owned by Memberships module via its repository).
- Delete member: transaction deleting notes/attendance; subscriptions/payments handled per decision below.

### Photos
- `image_picker` → copy to app documents dir (`path_provider`) under `member_photos/<id>.jpg`, compress (max 800px, quality 80). Store the relative path only. Delete the file when the member is deleted or the photo replaced. Include `member_photos/` in backup archive (links to the Backup module).

---

## 3. Domain Rules

- **Status resolution** (single pure function, unit-tested):
  1. `isSuspended` → `paused`
  2. no subscription, or end date has passed → `expired`
  3. ends within N days (setting) → `expiringSoon`
  4. else `active`
- Validation: name required (≥2 chars); phone required, 11 digits, unique (error: "رقم الهاتف يجب أن يكون 11 رقماً" / "الرقم مسجل لمشترك آخر"); age 5–100; weight 20–300; height 100–250 (all optional).
- **Check-in rules:** blocked for `paused` and `expired` (show dialog with "Renew" action); prevent duplicate check-in same day (confirm instead of silently adding). Attendance is a log only: it is never counted against the subscription.
- Use `fpdart` `Either<Failure, T>` in use cases; cubits map failures to Arabic messages.

### Decisions to confirm (defaults chosen)
1. Deleting a member with payment history → **default:** block delete and offer "Suspend" instead; allow delete only when there are no payments (financial records must stay intact).
2. Notes → plain text, multiple entries with timestamps (not a single field), shown in the Notes tab; the form also offers a quick first note.
3. Phone → 11-digit Egyptian format by default, validation configurable later.

---

## 4. State Management (Cubits)

| Cubit | State (freezed) | Responsibilities |
|---|---|---|
| `MembersListCubit` | `initial / loading / loaded(members, query, filter, count) / error` | Subscribes to `watchMembers`; debounce search 300 ms; status filter; pull-to-refresh |
| `MemberFormCubit` | `editing(form, isSaving, errors) / saved / failure` | Validation, photo pick, save (create/update) |
| `MemberDetailsCubit` | `loading / loaded(member, status, currentSub, stats) / error` | Streams details, pause/resume, delete |
| `MemberNotesCubit` | list + add/edit/delete | Notes CRUD |
| `AttendanceCubit` | `loaded(month, days, records)` | Month navigation, check-in, calendar markers |

Rules: cubits depend only on use cases; registered with `@injectable` (factory) and provided via `BlocProvider` at page level; `Equatable`/freezed states; one-shot events (snackbars/navigation) via `BlocListener` on dedicated state or `listenWhen`.

---

## 5. Routing (go_router)

```
/members                         MembersPage            (bottom-nav tab 2)
/members/new                     MemberFormPage
/members/:id                     MemberDetailsPage
/members/:id/edit                MemberFormPage(edit)
```
Shared-axis horizontal transition (250 ms, RTL-aware) per design §8. Renew / pause open bottom sheets from the Memberships module (§7.3 of design), invoked from member details.

---

## 6. UI — Screen by Screen (design.md §7.2)

### 6.1 Members list (المشتركين)
- App bar: title `titleLarge`; no elevation until scrolled.
- **Search field** (height 48, `radiusFull`, fill `surface`, 1px `border`, search icon start, clear icon end) — placeholder "ابحث بالاسم أو رقم الهاتف".
- **Filter chips** (horizontal scroll, height 36): الكل · نشط · ينتهي قريباً · منتهي · موقوف; selected = `primaryLight` fill, `primary` border, check icon.
- **Sticky count header:** "128 مشترك" (`bodyMedium`, `textSecondary`).
- **Member tile (§6.4):** 48 avatar (photo or initials on `primaryLight`/`primaryDark`), name `titleMedium`, "phone · package" `bodyMedium`, "ينتهي بعد 23 يوماً" line, **status chip** (§6.5: icon + label + tint, never color alone). Inset 1px dividers. Optional swipe: start = Call (success), end = Renew (primary). Min height keeps 48 dp touch target.
- **FAB:** `add_rounded`, bottom-end, opens form.
- Pull-to-refresh, skeleton shimmer while loading, **empty state** ("إضافة أول مشترك" button) and **no-results state** ("لا توجد نتائج" + clear search).
- Use `ListView.builder` + `ValueKey(member.id)` (performance on weak devices).

### 6.2 Add / Edit member form
- Single scroll page, sections spaced 24:
  1. **Photo:** 96 dp circular picker → bottom sheet (كاميرا / المعرض / حذف الصورة), `radiusXl` top corners, drag handle.
  2. **Basic:** name, phone (LTR digits inside RTL, numeric keyboard, `call_rounded` prefix).
  3. **Body info:** age, weight (kg), height (cm) in a 3-column row (units as suffix).
  4. **Notes:** multi-line optional field (create flow only; edit uses the Notes tab).
- Inputs: height 56, `radiusMd`, fill `surfaceVariant`, focus 2px `primary`, inline errors with icon.
- **Sticky bottom bar:** Save (primary, loading state in-button) + Cancel (outlined), equal width, gap 12, lifts above keyboard.
- Unsaved-changes guard: confirm dialog on back when dirty.
- After creating a member, snackbar "تمت إضافة المشترك" with action "اشتراك جديد" → opens renew/subscribe sheet (one-tap flow).

### 6.3 Member details
- **Header:** 80 avatar, name, status chip, phone with Call and WhatsApp icon buttons (`url_launcher`; tooltips in Arabic).
- **Action row:** تجديد (primary) · إيقاف مؤقت / استئناف (tonal) · تسجيل حضور (tonal). Equal widths, 52 height (small variants 40 in cards).
- **Body stats card:** age / weight / height as 3 mini stat cells.
- **Current membership card:** package, start → end, progress bar (`primary`; `warning` < 20 % left; `error` expired), remaining days, paid / remaining amount (from Finance).
- **Tabs** (الاشتراكات · الحضور · المدفوعات · الملاحظات):
  - **الاشتراكات:** history list (package, dates, price, status chip).
  - **الحضور:** month calendar with `primary` dots (month chevrons) + list of check-ins below (date, time).
  - **المدفوعات:** read-only list from Finance repository.
  - **الملاحظات:** note cards (`info` tint icon container), add via bottom sheet/FAB-style button, edit/delete with confirm dialog.
- App bar actions: edit, overflow → delete (Destructive button inside confirm dialog naming the member: "حذف المشترك أحمد؟").

### 6.4 Shared widgets (build first, reuse everywhere)
`StatusChip`, `MemberTile`, `AppTextField` (+ phone/money variants), `AppButton` (primary/tonal/outlined/destructive + loading), `EmptyState`, `ConfirmDialog`, `StatCard`, `PhotoPickerSheet`, `Avatar`.

---

## 7. Design-System Compliance Checklist
- [ ] Only `AppColors` / `AppSpacing` / `AppRadius`; zero literal hex or magic numbers
- [ ] `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`; no `left/right`
- [ ] Phone number fields forced LTR (`TextDirection.ltr`) inside RTL
- [ ] Touch targets ≥ 48 dp; buttons 52; inputs 56; text scale up to 1.3× without clipping
- [ ] Status = color + icon + text everywhere
- [ ] Cairo font via theme only; tabular figures for numeric columns
- [ ] Arabic strings via l10n (`app_ar.arb`, with `app_en.arb` stubs) — no hardcoded strings
- [ ] Semantics/tooltip labels (Arabic) on icon-only buttons
- [ ] Motion per §8; respect `disableAnimations`; light haptic on check-in
- [ ] Light theme only; no `darkTheme`

---

## 8. Implementation Phases

| Phase | Work | Output |
|---|---|---|
| **1. Foundation** | Shared widgets (StatusChip, AppTextField, AppButton, EmptyState, ConfirmDialog, Avatar); l10n keys; routes skeleton | Reusable design-system kit, widget/golden tests |
| **2. Data** | drift tables, DAOs, migration, mappers, repositories, `MemberStatus` resolver | DAO tests with in-memory drift DB; status resolver unit tests |
| **3. Domain** | Entities, use cases, failures, DI registration (`injectable`), `build_runner` | Use-case unit tests (mocktail) |
| **4. List screen** | `MembersListCubit`, search, filters, tile, empty/loading/error states, FAB | Working list with live data; bloc_test |
| **5. Add/Edit form** | `MemberFormCubit`, validation, photo flow, sticky bar, dirty guard | Create & edit member end-to-end |
| **6. Details** | Header, action row, stats, current membership card, history tab | Details page (read) |
| **7. Notes** | `MemberNotesCubit`, notes tab, add/edit/delete | Notes CRUD |
| **8. Attendance** | `AttendanceCubit`, check-in rules + haptics, calendar tab; hook up dashboard quick action "تسجيل حضور" and "today's check-ins" stat | Attendance flow |
| **9. Integration** | Pause/resume + renew sheets wiring (Memberships), balances (Finance), delete rules, photos in backup, export members CSV/PDF (`csv`/`pdf`) | Cross-module flows |
| **10. Polish & QA** | RTL pass, text-scale 1.3×, accessibility audit, performance with 2,000 members, empty states, goldens | Release candidate |

Estimated effort (solo dev): ≈ 8–11 working days.

---

## 9. Testing Strategy
- **Unit:** status resolver (boundary dates), phone normalization, validators, search normalization.
- **DAO/integration:** in-memory drift — search by name/phone, filters, cascade deletes, unique phone, migration up from previous schema.
- **Cubit (bloc_test):** list (debounce, filter), form (validation, save failure), attendance (blocked statuses, duplicate day), notes CRUD.
- **Widget/golden:** member tile (all four statuses), form validation states, empty states — in RTL and at text scale 1.3.
- **Manual device checklist:** one-hand reach to FAB and actions, camera/gallery permissions (Android 13+ photo picker), keyboard overlap on the form, offline behavior.

---

## 10. Risks & Mitigations
| Risk | Mitigation |
|---|---|
| Derived status inconsistent across screens | Single `resolveStatus` function used by list, details, dashboard |
| Slow list on large datasets / weak devices | Indexed queries, stream with limit/paging (`LIMIT/OFFSET` or keyset) if > 1,000 rows, const widgets, cached avatar decoding (`cacheWidth`) |
| Arabic search misses (hamza/ta marbuta) | Normalized `searchName` column |
| Photo storage bloat | Compress on save, delete on replace/delete |
| Accidental data loss | Confirm dialogs, delete blocked when payments exist, backup includes photos |
| Cross-module coupling | Only repository interfaces in `domain/`; no direct DAO access across features |

---

## 11. Definition of Done
All 7 spec bullets work offline; all checklist items in §7 pass; tests in §9 green; no analyzer warnings; reviewed on a 360 dp phone and a tablet (master-detail ≥ 600 dp per design §9).
