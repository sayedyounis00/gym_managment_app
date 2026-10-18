# Membership Management: Implementation Plan

**Stack:** Flutter (Material 3), clean architecture, Cubit (flutter_bloc), drift, get_it + injectable, go_router, freezed, fpdart
**Design source:** `design.md` (light theme only, Arabic-first RTL, Cairo font, primary `#F26B1D`)
**Scope:** Feature 3 of the spec, duration-based memberships only.

> Scope note: the spec line "visit-based memberships" is out of scope. Packages and subscriptions are **duration-based only**. The attendance log stays a plain history list.

---

## 1. Feature Scope

| # | Requirement | Where it lives in the UI |
|---|---|---|
| 1 | Create packages manually | Memberships tab: FAB, then Create/Edit Package page |
| 2 | Price and duration per package | Package form: price field, duration (days / months) |
| 3 | Record start and end dates | Renew bottom sheet, Member Details membership card |
| 4 | One-click renew | "تجديد" button: member details, expiring list, swipe action |
| 5 | Temporary suspend | Pause flow (sheet) and Resume button on member page |
| 6 | Notifications before expiry | Local notifications + dashboard banner, configurable days |

---

## 2. Domain Model

### Entities (`features/memberships/domain/entities/`)

**`MembershipPackage`**
- `id` (uuid), `name`, `price` (int, smallest unit or decimal per finance module convention), `durationValue`, `durationUnit` (`days | months`), `isActive`, `createdAt`

**`Subscription`** (a member's membership instance)
- `id`, `memberId`, `packageId`, `packageNameSnapshot`, `priceSnapshot`, `startDate`, `endDate`, `status` (`active | paused | expired`), `pausedAt?`, `pauseReason?`, `totalPausedDays`, `amountPaid`, `createdAt`

Derived (computed in domain, not stored):
- `remainingDays`, `progress` (0..1), `isExpiringSoon(thresholdDays)`
- `displayStatus` maps to the design's four states: `active`, `expiringSoon`, `expired`, `paused`
- `remainingAmount = priceSnapshot - amountPaid`

**Why snapshots:** editing a package price later must not change old subscriptions or finance history.

### Rules (pure Dart, unit-testable)
- `endDate = startDate + duration` (months use calendar month add, clamped to month end).
- Default renew start date: today, or the day after the current end date if the subscription is still active.
- Pause: store `pausedAt`. Resume: `endDate += (resumeDate - pausedAt)` and `totalPausedDays += that`. A paused subscription is never marked expired.
- Expired: `endDate < today` and not paused (evaluated on app open and in the daily background job).
- Cannot delete a package that has subscriptions. Deactivate (`isActive=false`) instead; inactive packages are hidden from pickers.

### Repository interface (`MembershipRepository`)
Returns `Either<Failure, T>` (fpdart).
- Packages: `watchPackages()`, `getPackage(id)`, `savePackage()`, `setPackageActive()`
- Subscriptions: `getCurrent(memberId)`, `getHistory(memberId)`, `renew(RenewParams)`, `pause(PauseParams)`, `resume(memberId)`, `watchExpiringWithin(days)`, `refreshExpiredStatuses()`

### Use cases (one class each, `call()`)
`GetPackages`, `SavePackage`, `TogglePackageActive`, `RenewSubscription`, `PauseSubscription`, `ResumeSubscription`, `GetMemberSubscriptionHistory`, `GetExpiringSubscriptions`, `RefreshExpiredStatuses`, `ScheduleExpiryNotifications`

---

## 3. Data Layer (drift)

### Tables
```
MembershipPackages: id TEXT PK, name, price, durationValue INT, durationUnit TEXT,
                    isActive BOOL default true, createdAt DATETIME
Subscriptions:      id TEXT PK, memberId FK, packageId FK, packageNameSnapshot,
                    priceSnapshot, startDate, endDate, status TEXT, pausedAt NULL,
                    pauseReason NULL, totalPausedDays INT default 0,
                    amountPaid, createdAt
```
Indexes: `Subscriptions(memberId)`, `Subscriptions(endDate)`, `Subscriptions(status)`.

### Atomic renew (single drift transaction)
1. Create the `Subscription` row.
2. Create the payment row via the Finance DAO (so revenue, balances and the dashboard update from one source of truth). Method is optional metadata: cash / transfer / wallet.
3. Mark the previous subscription as ended/expired if it was still open.

Because Finance owns payments, define a small `RecordPayment` use case in a shared `core` or finance domain and call it from the renew use case. Avoid duplicating payment logic.

### Files
```
features/memberships/data/
  datasources/membership_local_ds.dart      (drift DAOs)
  models/                                   (drift row <-> entity mappers)
  repositories/membership_repository_impl.dart
core/database/tables/membership_tables.dart
```
Create a drift migration (schema version bump) with a `schema` step that adds both tables; write a migration test.

---

## 4. State Management (Cubits)

| Cubit | State (freezed) | Responsibility |
|---|---|---|
| `PackagesCubit` | loading / loaded(list) / empty / error | List packages, toggle active |
| `PackageFormCubit` | form fields + validation + saving/success/failure | Create/edit package |
| `RenewCubit` | selected package, start date, amount paid, method, computed end date, remaining amount, submitting | Drives the renew bottom sheet (live remaining amount) |
| `PauseCubit` | reason, date, submitting | Pause/resume |
| `MemberSubscriptionCubit` | current subscription + history | Member Details tab and membership card |
| `ExpiringCubit` | list + threshold | Dashboard expiring list, banner count |

Rules: states are `Equatable`/freezed; every error is a `Failure` mapped to a specific Arabic message; no business logic in widgets.

---

## 5. UI Plan (follows `design.md`)

### 5.1 Memberships page (الباقات): section 7.3
- App bar: `titleLarge` "الباقات".
- List of **package cards** (surface, `radiusLg`, 1px `border`, padding 16):
  - Name `titleMedium`, price `headlineMedium` (tabular figures, currency `ج.م` via `intl`)
  - Duration text, e.g. "30 يوم" / "3 شهور"
  - Small badge "مدة" (`secondaryLight` bg, `secondary` text, `radiusFull`, `labelMedium`)
  - Edit icon button (48x48 hit area, `textSecondary`)
  - Inactive package: muted text + "غير مفعلة" chip
- FAB: `add_rounded`, label "إنشاء باقة" (Extended), bottom-end (left in RTL), elevation 3.
- Empty state: 64dp icon in 112 `primaryLight` circle, "لا توجد باقات بعد", hint, primary button "إنشاء أول باقة".
- Loading: skeleton shimmer (`#EEF0F4` / `#F9FAFB`).
- Error: `error_outline_rounded` + Retry outlined button.

### 5.2 Create/Edit Package page
Single scroll page, sticky bottom bar (Save primary + Cancel outlined, equal width, 12 gap, primary at the reading-start side):
- Name (text field, 56 high)
- Price (money field: numeric keyboard, thousands separator, currency suffix)
- Duration: number field + unit selector (Segmented: أيام / شهور, 44 high, `radiusFull`)
- "مفعلة" switch (active `primary`)
- No type selector, since only duration-based packages exist.

Validation (inline, specific, with icon): "اسم الباقة مطلوب", "السعر يجب أن يكون أكبر من صفر", "المدة يجب أن تكون يوماً واحداً على الأقل".

### 5.3 Renew bottom sheet: section 7.3
`radiusXl` top corners, drag handle, padding 16-24. Order:
1. Package selector (selector field opening a list sheet; only active packages)
2. Start date (date field with `calendar_month_rounded`; default per rules above)
3. End date (read-only, auto-computed, updates live)
4. Amount paid (money field, default full price)
5. Payment method chips: نقدي · تحويل · محفظة إلكترونية (36 high, selected = `primaryLight` fill, `primary` border, check icon, icons `payments_rounded` / `swap_horiz_rounded` / `account_balance_wallet_rounded`)
6. Remaining amount shown live: `success` if 0, `warning` chip "مدفوع جزئياً" if partial
7. Primary button "تأكيد التجديد" (52 high, 16 bold), loading state per design 6.1.

**One-click behavior:** the "تجديد" button opens the sheet pre-filled with the member's last package, default dates, and full payment, so confirming takes one more tap. Haptic: light impact on success. Snackbar: "تم تجديد اشتراك أحمد" with success icon.

### 5.4 Pause / Resume flow
- Bottom sheet: optional reason (multi-line), pause date (default today), confirm (tonal-to-primary per hierarchy; confirm is the filled button).
- After pause: member chip becomes "موقوف" (`paused` purple, `pause_circle` icon, tint background). Resume button appears on the member page ("استئناف").
- Resume shows a confirm dialog explaining the end date shift: "سيتم تمديد تاريخ الانتهاء بمقدار X يوم".

### 5.5 Member Details integration (section 7.2)
- Action row: تجديد (primary) · إيقاف مؤقت (tonal, becomes استئناف when paused) · تسجيل حضور (tonal).
- **Current membership card:** package, start → end, progress bar (primary; `warning` under 20% left; `error` when expired), remaining days, paid / remaining amount, payment chip.
- Tab "الاشتراكات": history list (package, dates, amount paid, status chip).

### 5.6 Dashboard integration (section 7.1)
- Expiring-soon stat card (warning) and warning banner "5 اشتراكات تنتهي خلال 3 أيام" (tap opens the Members list filtered by `expiringSoon`).
- Expiring list (next 5) with a small 40-high "تجديد" button each.

### 5.7 Reusable design-system widgets to add in `core/widgets/`
`StatusChip` (4 member states + 3 payment states, icon + text + tint), `PackageCard`, `AppButton` variants (if not already built), `AppTextField`, `MoneyField`, `DateField`, `SegmentedSelector`, `PaymentMethodChips`, `ConfirmDialog`, `EmptyState`, `SkeletonList`.

### 5.8 RTL and accessibility checklist (applies to every widget above)
- Only `EdgeInsetsDirectional` / `AlignmentDirectional`; swipe and arrow icons mirror.
- Touch targets at least 48 dp; tooltips/Semantics labels in Arabic on icon-only buttons.
- Status = icon + text + color, never color alone.
- Support text scale up to 1.3x without clipping.
- All strings in ARB / localization files (Arabic first, English-ready).
- No hardcoded colors: use `AppColors`, `AppSpacing`, `AppRadius` and theme tokens only.

---

## 6. Expiry Notifications

Packages already installed: `flutter_local_notifications`, `timezone`, `workmanager`, `permission_handler`.

1. **Permission:** request notification permission (Android 13+) the first time notifications are enabled, with a short rationale dialog. Exact alarms are not required; use inexact scheduling.
2. **Scheduling:** on renew/pause/resume/edit, re-schedule that subscription's notification at `endDate - N days` (N from Settings > التنبيهات, default 3). Cancel on pause; re-create on resume.
3. **Daily background job (`workmanager`):** once a day, run `RefreshExpiredStatuses` and fire a single grouped notification: "X اشتراكات تنتهي قريباً". This covers the device being restarted or notifications being cleared.
4. **In-app:** the dashboard banner reads the same `ExpiringCubit` data so the signal stays visible even if notifications are off.
5. **Tap handling:** notification payload deep-links through `go_router` to the filtered Members list.
6. Respect the settings toggle; if disabled, cancel all scheduled notifications.

---

## 7. Navigation (go_router)

```
/memberships                      (bottom nav tab 3)
/memberships/package/new
/memberships/package/:id/edit
/members/:id                      (existing; hosts renew + pause sheets)
```
Renew and pause are bottom sheets, not routes, so they can be launched from the dashboard, member list, and member details. Page transitions use shared axis (250 ms, `easeInOutCubic`, RTL-aware).

---

## 8. Dependency Injection
Register via `injectable`: DAOs, `MembershipRepositoryImpl` as `@LazySingleton(as: MembershipRepository)`, use cases as `@injectable`, Cubits as `@injectable` (factory) provided with `BlocProvider` at page level. Run `build_runner` after adding annotations.

---

## 9. Implementation Phases

| Phase | Work | Output / Done when |
|---|---|---|
| 1. Foundation | Entities, rules (end date, pause math, status), drift tables + migration, DAOs, repo interface | Unit tests for date/pause/status rules pass; migration test passes |
| 2. Data | Repo impl, atomic renew transaction (with finance payment), `RefreshExpiredStatuses` | Repository tests with in-memory drift pass |
| 3. Design-system widgets | `StatusChip`, `MoneyField`, `DateField`, `SegmentedSelector`, `PaymentMethodChips`, `EmptyState`, skeletons | Widgets match design.md tokens; golden/widget tests |
| 4. Packages UI | `PackagesCubit`, list page, form page, validation | Create/edit/deactivate package works end to end |
| 5. Renew flow | `RenewCubit`, sheet, live remaining amount, finance integration | Renewal creates a subscription and a payment; dashboard revenue updates |
| 6. Pause/Resume | `PauseCubit`, sheets, end-date shift, status chip | Pause/resume correct to the day; chip updates |
| 7. Integration | Member Details card + history tab, dashboard banner/list, Members filter chips | All entry points open the same renew sheet |
| 8. Notifications | Scheduling, daily job, permission flow, deep link | Notification fires at the configured day; cancelled on pause |
| 9. Polish & QA | RTL pass, text scale 1.3x, accessibility labels, motion/haptics, empty/error/loading states | Checklist in 5.8 fully ticked |

Suggested order of value: phases 1 to 5 deliver a usable renewal system; 6 to 9 complete the spec.

---

## 10. Testing Plan

- **Unit:** end-date calculation (days and months, month-end clamping, leap years), default start date, pause/resume shifts, status derivation (active / expiring soon / expired / paused), remaining amount, Cubit transitions (`bloc_test`, `mocktail`).
- **Data:** drift in-memory tests for transactions (renew rolls back fully if the payment insert fails), migration from the previous schema version.
- **Widget:** package card, status chips (icon + label per state), renew sheet live updates, form validation messages, RTL golden checks.
- **Manual device checks:** notification delivery after reboot, background job on a low-end device, backup/restore includes the new tables (coordinate with feature 5).

---

## 11. Edge Cases to Handle
- Renewing an active subscription early: new period starts the day after the current end (no lost days).
- Renewing an expired subscription: starts today by default, editable.
- Partial payment at renewal: remaining balance appears in Finance "Members with balances".
- Package price edited after sales: old subscriptions keep their snapshot price.
- Pausing an already-expired subscription: blocked with a clear message.
- Device date/timezone change: statuses recomputed on app resume.
- Deleting a member: confirm dialog naming the member; subscription history handling follows the Members module rule.
- Backup/restore and CSV/PDF export must include packages and subscriptions.

---

## 12. Definition of Done
- [ ] All six spec items work end to end (duration-based only).
- [ ] Every screen uses only design-system tokens and shared widgets.
- [ ] RTL verified; Arabic copy follows the tone guide (verbs on buttons, relative dates).
- [ ] Light theme only; no dark theme code introduced.
- [ ] Touch targets, Semantics labels, and text scale checks pass.
- [ ] Unit, repository, and widget tests green; migration verified.
- [ ] Notifications verified on a real Android device.
