# Dashboard Feature Plan (Flutter, Clean Architecture + Cubit + Drift)

The dashboard only reads data from other features (members, memberships, payments, expenses), so build it after those tables exist, or start with the Drift schema and seed data below.

## 1. Data requirements (Drift tables the queries need)

| Dashboard item | Needs |
|---|---|
| Active members | `members.status = active` |
| Expiring soon | `subscriptions.end_date` between today and today + N days (default 7), plus remaining visits for visit-based plans |
| New subscriptions this month | `subscriptions.start_date` within the current month, with `is_renewal` to separate new from renewed |
| Revenue | `payments.amount` summed over the period |
| Expenses | `expenses.amount` summed over the period |
| Net profit | revenue − expenses |

Index `end_date`, `status`, and `paid_at`/`date` so the queries stay fast.

## 2. Folder structure

```
features/dashboard/
├── domain/
│   ├── entities/        dashboard_summary.dart, expiring_subscription.dart
│   ├── repositories/    dashboard_repository.dart
│   └── usecases/        get_dashboard_summary.dart
├── data/
│   ├── datasources/     dashboard_local_datasource.dart (Drift queries / DAO)
│   ├── models/          (only if you need mapping from query rows)
│   └── repositories/    dashboard_repository_impl.dart
└── presentation/
    ├── cubit/           dashboard_cubit.dart, dashboard_state.dart
    ├── pages/           dashboard_page.dart
    └── widgets/         stat_card.dart, expiring_list.dart, finance_summary.dart
```

## 3. Domain layer

- `DashboardSummary` (Equatable/Freezed) holds:
  - `activeMembersCount`
  - `newSubscriptionsThisMonth`
  - `expiringSoon` (list of `ExpiringSubscription`: member name, phone, end date, days left)
  - `monthRevenue`, `monthExpenses`, `netProfit` (computed getter)
  - Optionally `todayRevenue`, since the spec says "summary of your day".
- `DashboardRepository.getSummary({DateTime now}) → Future<Either<Failure, DashboardSummary>>`, using fpdart. Passing `now` makes the logic testable.
- `GetDashboardSummary` use case wraps the repository call.

## 4. Data layer

- Put the queries in a Drift DAO, using aggregate queries (`count`, `sum`) rather than loading rows into Dart.
- Use a Drift `watch()` stream so the dashboard updates when a payment or member changes, with no manual refresh.
- Compute month boundaries (first day to first day of next month) in one helper, and store dates consistently (UTC or local, not mixed).
- The repository maps exceptions to `Failure` and combines the queries with `Future.wait` or a Drift transaction.

## 5. Presentation layer

- `DashboardState` (Freezed): `initial | loading | loaded(summary) | error(message)`.
- `DashboardCubit` loads on creation, subscribes to the stream, and cancels the subscription in `close()`.
- Add a pull-to-refresh action as a fallback.
- Layout, top to bottom:
  1. Greeting and date.
  2. 2×2 grid of stat cards: active members, new this month, expiring soon, net profit.
  3. Finance card with revenue, expenses, and net profit. Use green for positive and red for negative. `fl_chart` can add a small bar or line chart later.
  4. Expiring-soon list (name, days left), with tap-to-open member details, a call button, and a WhatsApp button via `url_launcher`.
- Handle empty states (no expiring subscriptions) and make the layout RTL-safe for Arabic.
- Format currency and dates with `intl`, using the `ar` locale if you localize.

## 6. Wiring

- Register the data source, repository, use case, and cubit with `injectable` and `get_it`, then run `build_runner`.
- Add the `/dashboard` route in `go_router` as the home route after the auth/PIN lock.
- Cards navigate to Members (filtered by status) and Finance.

## 7. Notifications (optional, connects to the spec's "alerts before expiry")

Use `workmanager` and `flutter_local_notifications` for a daily check that notifies about subscriptions expiring tomorrow. This can be a separate task from the dashboard UI.

## 8. Testing

- Unit tests for the use case and the profit calculation (`mocktail`).
- Cubit tests with `bloc_test`: loading → loaded, loading → error, and stream updates.
- DAO tests using Drift's in-memory database with seeded data. Include edge cases: a subscription ending today, the first or last day of the month, and a paused member.
- A widget test for the empty and negative-profit states.

## 9. Suggested build order

1. Drift tables and DAO queries, with seeded test data.
2. Entities, repository, and use case.
3. Cubit and state, with tests.
4. Dashboard UI with stat cards.
5. Finance card and expiring list.
6. DI and routing.
7. Streams for live updates, empty and error states, and polish (RTL, formatting).
8. Optional: charts and expiry notifications.

## Decisions to confirm

- **"Expiring soon" window:** 7 days is the default keep it  7 days no configs 
- **Visit-based plans:**no i dont want to assign visits day for users 
- **Month boundaries:** rolling 30 days make it this 
- **Paused members:** exclude them from "active" and from expiring alerts? yes exxlude them 