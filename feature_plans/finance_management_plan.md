# Finance Management: Implementation Plan

**App:** Gym Management (Flutter, Material 3, light only, Arabic RTL-first)
**Architecture:** Clean architecture, Cubit (flutter_bloc), get_it + injectable, drift, fpdart, freezed
**Source spec:** Section 4 of `gym_plan.txt` · **Design source of truth:** `design.md` (sections 2-8, 10-11)

Project decisions this plan respects:
- No visit-based memberships or visit counting. Everything is duration-based.
- Billing model: a pack's month can be paid in installments (e.g. 4 x 50 EGP for a 200 EGP/month pack). When all installments are paid, the month is marked fully paid.
- No PIN, fingerprint or lock screen anywhere.
- Loading states use `skeletonizer` with the subtle liquid-glass look.
- Payment method (cash / transfer / e-wallet) is optional metadata only.

---

## 1. Scope

| Spec requirement | Delivered as |
|---|---|
| Record membership payments | Add Payment sheet, tied to a member's billing month/installment |
| Paid and outstanding per member | Member balance card + "Members with balances" list |
| Record expenses (rent, electricity, water, maintenance, other) | Add Expense form with category chips |
| Daily and monthly revenue | Aggregate queries, Finance header + dashboard + reports |
| Estimated net profit | Revenue minus Expenses, shown in Finance header and dashboard hero card |
| Complete record of all transactions | Unified ledger (payments + expenses), void instead of delete |
| Cash / bank transfer / e-wallet optional | Nullable `method` field and method chips |

Out of scope here: attendance, member CRUD, pack creation, backup/restore. This feature only hooks into them.

---

## 2. Data Layer (drift)

### 2.1 Money rule
Store all amounts as **integer piasters** (`int`), never `double`. Convert at the UI edge with `intl` `NumberFormat.currency` (default `ج.م`, configurable per design 3).

### 2.2 Tables

**`payments`** (income)
| Column | Type | Notes |
|---|---|---|
| id | text (uuid) | PK |
| memberId | text | FK members |
| subscriptionId | text | FK subscriptions |
| billingPeriodId | text? | FK billing period (the pack month) the payment is applied to |
| amount | int | > 0 |
| method | text? | `cash` / `transfer` / `wallet` / null |
| paidAt | datetime | defaults to now, editable |
| note | text? | |
| createdAt | datetime | |
| voidedAt | datetime? | soft void |
| voidReason | text? | |

**`expenses`**
| Column | Type | Notes |
|---|---|---|
| id | text (uuid) | PK |
| category | text | `rent` / `electricity` / `water` / `maintenance` / `other` |
| customLabel | text? | required when category = other |
| amount | int | > 0 |
| method | text? | optional |
| date | datetime | |
| note | text? | |
| createdAt | datetime | |
| voidedAt | datetime? | |

**Billing periods:** the installment model needs a per-month record (`dueAmount`, `periodStart`, `periodEnd`, `status`). If the memberships feature already created it, reuse it. If not, create it as part of this work and coordinate with the memberships owner (you).
- A period's `paidAmount` = sum of non-voided payments pointing to it.
- Period status derives from amounts: `unpaid` (0), `partial` (0 < paid < due), `paid` (paid >= due). Never store it separately, to avoid drift.
- Payments are split as many times as needed (4 x 50 EGP). Overpaying a period is blocked in the UI; an excess can optionally roll into the next period (see 6.2).

### 2.3 Unified ledger
Add a drift **view/query** `ledger_entries` that UNIONs payments (type income) and expenses (type expense) with: `id, type, amount, date, title, subtitle, method, memberId?, category?, voided`. This powers the transaction list, daily grouping, reports and export without duplicating data.

### 2.4 DAOs and queries
- `PaymentsDao`: insert, void, watchByMember, watchByPeriod, sumBetween(from, to).
- `ExpensesDao`: insert, update, void, watchBetween, sumBetween.
- `FinanceDao`: `watchLedger(range, filter)`, `dailyTotals(range)`, `monthlySummary(month)`, `membersWithBalance()`.
- Add indexes on `payments(memberId)`, `payments(paidAt)`, `expenses(date)`.
- Write migrations with a schema version bump and a migration test.

---

## 3. Domain Layer

**Entities (freezed + equatable):** `Payment`, `Expense`, `LedgerEntry`, `FinanceSummary {revenue, expenses, net}`, `DailyTotal`, `MemberBalance {member, totalDue, totalPaid, remaining}`, enums `PaymentMethod`, `ExpenseCategory`, `LedgerType`, `PaymentStatus {paid, partial, unpaid}`.

**Repository contracts** (`Either<Failure, T>` via fpdart):
- `FinanceRepository`: `watchSummary(month)`, `watchLedger(...)`, `getDailyTotals(...)`, `getMembersWithBalance()`, `exportReport(...)`.
- `PaymentRepository`: `addPayment`, `voidPayment`, `watchMemberPayments`.
- `ExpenseRepository`: `addExpense`, `updateExpense`, `voidExpense`.

**Use cases (single responsibility):** `AddPayment`, `VoidPayment`, `AddExpense`, `UpdateExpense`, `VoidExpense`, `GetFinanceSummary`, `WatchLedger`, `GetDailyTotals`, `GetMembersWithBalance`, `GetMemberBalance`, `ExportFinanceReport`.

**Validation rules (in use cases, not UI):**
- Amount must be > 0 and, for payments, <= the remaining on the chosen period.
- Expense with category `other` requires a label.
- Dates cannot be in the future (soft warning, not block, for backdated entries is fine).
- Voiding requires confirmation from the UI; the use case just records `voidedAt`.

---

## 4. Presentation Layer (Cubits)

Folder: `lib/features/finance/presentation/{pages,widgets,cubit}`

| Cubit | State (freezed) | Responsibility |
|---|---|---|
| `FinanceOverviewCubit` | loading / loaded(summary, selectedMonth) / error | Month selector, 3-cell summary |
| `LedgerCubit` | loading / loaded(groupedByDay, filter) / empty / error | All / Income / Expenses tabs, day grouping with daily totals |
| `AddPaymentCubit` | form state + submitting / success / failure | Member pick, period pick, amount, method, live remaining |
| `AddExpenseCubit` | form state + submitting / success / failure | Category, amount, date, method, note |
| `BalancesCubit` | loading / loaded / empty / error | Members who owe money |
| `ReportsCubit` | range (day/month), chart data, exporting | Chart + PDF/CSV export |

Rules: streams from drift feed cubits so every screen (dashboard, member page, finance) updates live after a write. Register everything with `@injectable`.

---

## 5. UI Specification (design.md compliant)

### 5.1 Finance screen (الحسابات), bottom nav destination 4
Per design 7.4:
1. **App bar** (`titleLarge`, surface, no elevation until scrolled).
2. **Month selector:** chevrons + month name (chevrons flip in RTL).
3. **Three-cell summary card** (surface, `radiusLg`, 1px border): Revenue (`success`) · Expenses (`error`) · Net (`primary`). Numbers use `headlineMedium` with tabular figures. Calm neutral surface; green/red only carry income/expense meaning (principle 6).
4. **Segmented control** (height 44, radiusFull): الكل · الإيرادات · المصروفات.
5. **Members with balances** list card: avatar, name, remaining amount in `error`, tap opens Add Payment prefilled.
6. **Transaction list** grouped by day with sticky day headers and daily totals.
7. **Extended FAB** "إضافة" (bottom-end, left in RTL) opening a bottom sheet with two choices: تسجيل دفعة / تسجيل مصروف.

### 5.2 Transaction row (design 6.10)
Leading 40x40 icon container (income = `successTint` + `success`, expense = `errorTint` + `error`), title + category/method line (`bodyMedium`, `textSecondary`), trailing amount `titleMedium` tabular figures with `+` success / `−` error, date under it. Voided rows: strikethrough amount, `textDisabled`, small "ملغاة" chip.

Method icons: cash `payments_rounded`, transfer `swap_horiz_rounded`, e-wallet `account_balance_wallet_rounded`. Hidden entirely if no method was chosen.

### 5.3 Add Payment (bottom sheet, `radiusXl`, drag handle)
Flow: choose member (search field radiusFull) → choose month/period → amount (money field: numeric keyboard, thousands separator, currency suffix; default = remaining of the period) → optional method chips (نقدي · تحويل · محفظة إلكترونية) → date → note. A live line shows **remaining after this payment** and the payment chip state (مدفوع / مدفوع جزئياً / غير مدفوع using success/warning/error tints with icons).
Buttons: primary "تأكيد الدفعة" (52 high, bold 16) + outlined "إلغاء", equal width, 12 gap, primary on the reading-start side (right in RTL). Loading state replaces the label with a 20dp spinner. Light haptic on success.

### 5.4 Add Expense (single page form)
Category chips (إيجار · كهرباء · مياه · صيانة · أخرى), amount, date (themed Material picker with `calendar_month_rounded`), optional method chips, note. "أخرى" reveals a required label field. Sticky bottom bar: Save (primary) + Cancel (outlined) that lifts above the keyboard.

### 5.5 Member Details integration
- **Current membership card:** show paid / remaining and the installment progress bar (primary; warning under 20% left, error when expired, per design 7.2).
- **المدفوعات tab:** list of that member's payments grouped by billing month, with a per-month chip (مدفوع / مدفوع جزئياً / غير مدفوع) and a "تسجيل دفعة" small button (height 40).
- Renew flow (existing bottom sheet) calls `AddPayment` for the amount paid at renewal, so there is one payment code path.

### 5.6 Dashboard integration (design 7.1)
- **Hero card** (the only gradient `primary → #FF8A47`): net profit this month with Revenue and Expenses sub-values inside.
- **Revenue vs Expenses bar chart** with Day / Week / Month segmented control (fl_chart; revenue `#1E9E5A`, expenses `#D93C3C`, net `#F26B1D`; horizontal dashed grid, bar width 16, top radius 6).
- **Quick actions:** "تسجيل دفعة" and "مصروف جديد" tiles open the same sheets as the Finance FAB.
- Counter count-up 500 ms on first load only.

### 5.7 Reports and export
Daily / monthly view with the chart and an outlined **Export** button (PDF via `pdf` + `printing`, CSV via `csv`, shared with `share_plus`). Table header uses `surfaceVariant`, `labelMedium` bold, `textSecondary`. Arabic font (Cairo) must be embedded in the PDF.

### 5.8 States
- **Loading:** `skeletonizer` shimmer on stat cells, transaction rows and balance list, using the liquid-glass loader styling (base `#EEF0F4`, highlight `#F9FAFB`, soft translucent surface). Spinner only for short blocking actions.
- **Empty:** 64dp icon in 112 `primaryLight` circle, title, one-line hint, primary button ("تسجيل أول دفعة").
- **Error:** `error_outline_rounded`, message, outlined Retry.
- **Void confirmation:** dialog naming the item ("إلغاء دفعة أحمد بقيمة 50 ج.م؟"), Destructive button, medium haptic.

### 5.9 Copy (Arabic, MSA, verbs on buttons)
Use "حفظ، إضافة، تأكيد، إلغاء". Errors must be specific and inline, for example "المبلغ أكبر من المتبقي (150 ج.م)". Dates as `12 نوفمبر 2026`.

---

## 6. Business Logic Details

### 6.1 Balance calculation
- Member remaining = sum(period `dueAmount`) − sum(non-voided payments) across the member's periods up to and including the current one.
- Revenue = sum of non-voided payments in range (by `paidAt`). Expenses = sum of non-voided expenses (by `date`). Net = Revenue − Expenses. Label net as "تقديري" (estimated), as the spec says.
- Daily revenue uses the device timezone day boundary.

### 6.2 Edge cases
- **Overpayment:** block by default; offer "apply the excess to next month" only if the next period exists.
- **Voiding a payment:** period status recomputes automatically; ledger keeps the voided row visible but excluded from totals.
- **Pausing a membership:** no new period accrues while paused; existing balances stay collectible.
- **Member deleted/archived:** keep payments in the ledger with a stored member name snapshot so history never breaks.
- **Changed pack price:** already-created periods keep their original `dueAmount`.

---

## 7. Cross-feature Hooks

| Feature | Hook |
|---|---|
| Memberships / Renew | Writes a payment through `AddPayment`; creates the billing period |
| Members | Balance chip on list tile (optional), المدفوعات tab |
| Dashboard | Summary, chart, quick actions, expiring-with-balance hint |
| Notifications | Optional daily reminder for outstanding balances (reuse flutter_local_notifications) |
| Backup/Restore & Export | Include `payments`, `expenses`, billing periods in backup; finance report export reuses 5.7 |

---

## 8. Delivery Phases

| Phase | Work | Done when |
|---|---|---|
| 1. Data | Tables, migrations, DAOs, ledger view, indexes | DAO unit tests pass on in-memory drift |
| 2. Domain | Entities, repositories, use cases, validation | Use case tests cover all rules in 3 and 6 |
| 3. Core UI kit | `AppButton`, money field, method chips, `StatusChip` (payment variants), transaction row, summary cell, empty/error/skeleton widgets in `core/widgets` | Widgets match design.md tokens |
| 4. Finance screens | Overview, ledger, balances, FAB sheet, Add Expense | Golden tests in RTL |
| 5. Payments | Add Payment sheet, member المدفوعات tab, renew integration | Installment flow works end to end |
| 6. Dashboard + Reports | Hero card, chart, quick actions, PDF/CSV export | Numbers match Finance screen |
| 7. Polish | Haptics, motion, accessibility, text scale 1.3x, tablet layout | Checklist in section 10 passes |

Suggested order inside each phase: tests first for data/domain, then cubit with `bloc_test`, then widgets.

---

## 9. Testing

- **Unit:** money math, balance and status derivation, validation, daily/monthly aggregation (including month boundaries and timezone).
- **DAO:** drift in-memory DB, void behavior, ledger union ordering.
- **Cubit:** `bloc_test` + `mocktail` for every cubit transition (loading, loaded, empty, error, submit success/failure).
- **Widget/golden:** Finance screen, Add Payment sheet, transaction rows, in RTL at 1.0x and 1.3x text scale.
- **Manual script:** add member → assign pack → pay 4 installments → month turns مدفوع → add expenses → verify net on dashboard and report → void a payment → verify totals → export PDF/CSV.

---

## 10. Design System Compliance Checklist

- [ ] Light theme only; colors only from `AppColors` tokens (no hardcoded hex in widgets)
- [ ] All spacing/radius from `AppSpacing`/`AppRadius`; screen padding 16, card padding 16, card gap 12
- [ ] `EdgeInsetsDirectional` / `AlignmentDirectional` everywhere; chevrons and back arrows flip in RTL
- [ ] Buttons 52 high, radius 12, `labelLarge`; primary text is bold 16sp (never small text on `primary`)
- [ ] Touch targets >= 48dp; icon-only buttons have Arabic tooltips/Semantics
- [ ] Status shown by icon + label + color, never color alone
- [ ] Green/red used only for income/expense meaning on money screens
- [ ] Tabular figures on all money columns; Western digits by default
- [ ] Cards use 1px border, elevation 0; only the dashboard hero card uses the gradient
- [ ] Skeletonizer loading with liquid-glass style; empty and error states on every list
- [ ] Destructive actions behind named confirm dialogs
- [ ] Motion durations per design section 8; respects `disableAnimations`
- [ ] No PIN/biometric/lock UI introduced; no visit-based wording anywhere

---

## 11. Files to Add

```
lib/features/finance/
  data/
    tables/payments_table.dart, expenses_table.dart
    daos/payments_dao.dart, expenses_dao.dart, finance_dao.dart
    models/ (mappers to entities)
    repositories/finance_repository_impl.dart, payment_repository_impl.dart, expense_repository_impl.dart
  domain/
    entities/ (payment, expense, ledger_entry, finance_summary, member_balance)
    repositories/ (contracts)
    usecases/ (list in section 3)
  presentation/
    cubit/ (overview, ledger, add_payment, add_expense, balances, reports)
    pages/ finance_page.dart, add_expense_page.dart, reports_page.dart
    widgets/ summary_card.dart, transaction_tile.dart, add_payment_sheet.dart,
             add_choice_sheet.dart, balance_tile.dart, method_chips.dart, category_chips.dart
lib/core/widgets/  money_field.dart, payment_status_chip.dart (extend status_chip.dart)
```

## 12. Open Questions (defaults chosen if you do not answer)

1. Should the "members with balances" list also show a call/WhatsApp shortcut? *Default: yes, call icon only.*
2. Allow editing a payment after saving, or void and re-enter only? *Default: void and re-enter, which keeps the audit trail clean.*
3. Currency symbol configurable in Settings now, or later? *Default: EGP fixed, configurable later.*
