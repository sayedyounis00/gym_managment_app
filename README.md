# Spear Gym Management App 🏋️‍♂️

A modern, offline-first mobile application designed for gym owners, fitness clubs, and personal trainers to manage members, subscriptions, finances, attendance, and analytics seamlessly from their mobile devices.

Built with **Flutter** using **Clean Architecture** and **BLoC (Cubit)** state management.

---

## 🌟 Key Features

### 👤 Member Management
- **Comprehensive Profiles**: Store personal information, contact info, emergency contacts, and profile photos (with camera capture & cropping).
- **Body Metrics & BMI**: Track height, weight, and automatically calculate BMI categories.
- **Attendance Calendar**: Visual monthly calendar view tracking daily member check-ins.
- **Member Notes**: Maintain coaching notes and logs per member.
- **Status Controls**: Active, suspended, and expired member statuses with fast search & filter.

### 💳 Membership & Package Lifecycle
- **Custom Packages**: Create recurring or fixed-duration gym plans (duration, price, session limits).
- **Subscription Management**: Assign memberships, handle renewals, and pause active subscriptions.
- **Expiry Alerts**: Automated dashboard alerts for subscriptions nearing expiration.

### 💰 Finance & Ledger
- **Payment Processing**: Record member payments across multiple payment methods (Cash, Card, Transfer).
- **Expense Tracking**: Categorize daily operational gym expenses (utilities, equipment, maintenance).
- **Ledger & Summaries**: Real-time revenue, expense, and net profit calculations.
- **Invoices & Exports**: Generate and print professional PDF receipts and export ledger/members to CSV.

### 📊 Dashboard & Analytics
- **Live Overview**: High-level KPIs including active members, expiring passes, today's check-ins, and monthly cash flow.
- **Interactive Visualizations**: Financial and attendance trend charts powered by `fl_chart`.
- **Actionable Banners**: Quick shortcuts for pending renewals and database backup reminders.

### 🔒 Security & Privacy
- **Biometric Lock**: Fingerprint and Face ID authentication via `local_auth`.
- **PIN Protection**: Fallback secure PIN support stored securely via `flutter_secure_storage`.
- **100% Offline-First**: Zero mandatory cloud dependency; client data stays private on the device.

### ⚙️ Utilities & Background Automation
- **Database Backup & Restore**: Full local backup archive generation and safe restore.
- **Automated Notifications**: Background tasks (`workmanager`) schedule local alerts for expiring memberships.

---

## 🏗️ Architecture & Tech Stack

The application follows **Clean Architecture** principles separated into Presentation, Domain, and Data layers:

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x)
- **State Management**: [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) (Cubit)
- **Local Database**: [`drift`](https://pub.dev/packages/drift) (Type-safe SQLite persistence)
- **Dependency Injection**: [`get_it`](https://pub.dev/packages/get_it) & [`injectable`](https://pub.dev/packages/injectable)
- **Navigation**: [`go_router`](https://pub.dev/packages/go_router)
- **Charts**: [`fl_chart`](https://pub.dev/packages/fl_chart)
- **Document Generation**: [`pdf`](https://pub.dev/packages/pdf) & [`printing`](https://pub.dev/packages/printing)
- **Background Tasks**: [`workmanager`](https://pub.dev/packages/workmanager) & [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
- **Code Generation**: `build_runner`, `freezed`, `drift_dev`, `json_serializable`

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants/       # App constants and style tokens
│   ├── database/        # Drift database, tables, DAOs & migrations
│   ├── di/              # Dependency injection setup (GetIt / Injectable)
│   ├── errors/          # Failures and exception handlers
│   ├── router/          # Declarative routing configurations
│   ├── services/        # Device-level services (biometrics, notifications)
│   ├── theme/           # Light & dark theme palettes
│   └── widgets/         # Shared global widgets & skeleton loaders
└── features/
    ├── dashboard/       # KPI cards, charts, alerts
    ├── members/         # Member list, profile, attendance, BMI, notes
    ├── memberships/     # Membership packages, subscribe, renew, pause
    ├── finance/         # Payments, expenses, ledger, PDF invoicing
    ├── security/        # Biometrics, PIN lock verification
    └── settings/        # Database backup/restore, CSV/PDF exports
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.13.3` or higher
- Android SDK / Xcode for iOS emulation or physical device testing

### Installation
1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd gym_managment_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

Run unit and widget tests:
```bash
flutter test
```
