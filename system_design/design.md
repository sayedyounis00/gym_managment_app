# Gym Management App — Design System

**Platform:** Flutter (Material 3) · **Theme:** Light only · **Language:** Arabic-first, RTL (English-ready)
**Users:** Gym owner (single user, one device) · **Mood:** Energetic, clean, trustworthy, fast to scan

> Light theme only. Do not ship `darkTheme`. Set `themeMode: ThemeMode.light` and `darkTheme: null` in `MaterialApp`.

---

## 1. Design Principles

1. **Glanceable:** The owner opens the app at the front desk. The key number (active members, expiring soon, today's income) must be readable in under 2 seconds.
2. **One-tap actions:** Renew, add payment, check in. The most common actions never take more than two taps.
3. **Clear status by color + label + icon:** Never color alone (active / expired / paused).
4. **RTL first:** Layouts mirror naturally. Use `EdgeInsetsDirectional`, `AlignmentDirectional`, and `Directionality` from locale, never hardcoded left/right.
5. **Large touch targets:** Minimum 48×48 dp. Spacing is generous, since the owner may use it with one hand while moving.
6. **Calm finance:** Money screens use neutral surfaces. Green and red are used only for income and expense meaning.

---

## 2. Color Palette

### 2.1 Brand

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#F26B1D` | Primary buttons, FAB, active nav item, key accents (energetic orange) |
| `primaryDark` | `#C9520D` | Pressed state, app bar accents |
| `primaryLight` | `#FFE6D6` | Tinted backgrounds, selected chips, icon containers |
| `onPrimary` | `#FFFFFF` | Text/icons on primary |
| `secondary` | `#1F2A44` | Headings accents, secondary buttons, dark-on-light emphasis (deep navy) |
| `secondaryLight` | `#E8EBF2` | Secondary tinted backgrounds |
| `onSecondary` | `#FFFFFF` | Text/icons on secondary |

### 2.2 Neutrals (light surfaces)

| Token | Hex | Usage |
|---|---|---|
| `background` | `#F7F8FA` | Scaffold background |
| `surface` | `#FFFFFF` | Cards, sheets, dialogs, app bar |
| `surfaceVariant` | `#F1F3F6` | Input fill, disabled areas, table header |
| `border` | `#E3E6EC` | Card borders, dividers, input outline |
| `borderStrong` | `#C9CED8` | Focused neutral outlines, checkboxes |
| `textPrimary` | `#1B2130` | Titles, body, numbers |
| `textSecondary` | `#5B6475` | Subtitles, labels, hints |
| `textDisabled` | `#9AA1AF` | Disabled text, placeholders |
| `overlay` | `#1B2130` @ 40% | Modal scrim |

### 2.3 Semantic

| Token | Hex | Light tint | Usage |
|---|---|---|---|
| `success` | `#1E9E5A` | `#E3F6EC` | Active member, paid, income, success snackbar |
| `warning` | `#E59A0B` | `#FFF3D6` | Expiring soon, partially paid |
| `error` | `#D93C3C` | `#FDE7E7` | Expired, unpaid, expense, delete, validation errors |
| `info` | `#2F6FDE` | `#E4EEFD` | Notes, informational banners |
| `paused` | `#7A52CC` | `#EEE8FA` | Suspended / frozen membership |

### 2.4 Member Status Mapping

| Status (Arabic) | Key | Color | Tint | Icon |
|---|---|---|---|---|
| نشط | `active` | `success` | `successTint` | `check_circle` |
| ينتهي قريباً | `expiringSoon` | `warning` | `warningTint` | `schedule` |
| منتهي | `expired` | `error` | `errorTint` | `cancel` |
| موقوف | `paused` | `paused` | `pausedTint` | `pause_circle` |

### 2.5 Chart Palette (fl_chart)

Revenue `#1E9E5A` · Expenses `#D93C3C` · Net profit `#F26B1D` · New members `#2F6FDE` · Grid lines `#E3E6EC`

### 2.6 Contrast

- `textPrimary` on `surface`/`background`: ≥ 12:1.
- `textSecondary` on `surface`: ≥ 5:1 (AA).
- `onPrimary` on `primary`: 3.4:1, so use **bold 16sp+** text on primary buttons (large-text AA). Never use small regular text on `primary`.

---

## 3. Typography

**Font family:** `Cairo` (Arabic + Latin, excellent number legibility). Fallback: `Tajawal`, `Roboto`.
Add via `google_fonts` or bundle in `assets/fonts/` (bundling recommended so the app works fully offline).

| Style | Size | Weight | Line height | Usage |
|---|---|---|---|---|
| `displayLarge` | 32 | 700 | 1.2 | Big dashboard figures (net profit) |
| `headlineMedium` | 24 | 700 | 1.3 | Screen titles, stat values |
| `titleLarge` | 20 | 700 | 1.3 | App bar title, section headers |
| `titleMedium` | 16 | 600 | 1.4 | Card titles, member name, list headers |
| `bodyLarge` | 16 | 400 | 1.5 | Main body text, inputs |
| `bodyMedium` | 14 | 400 | 1.5 | Secondary text, list subtitles |
| `labelLarge` | 16 | 700 | 1.2 | Button text |
| `labelMedium` | 12 | 600 | 1.2 | Chips, badges, captions |

**Numbers:** Use Western digits (0-9) by default for phone numbers, prices, and dates for fast scanning; make this a setting (`Intl` locale `ar_EG` vs `en`). Use `FontFeature.tabularFigures()` in tables and money columns so digits align.

**Currency:** Format with `intl` (`NumberFormat.currency`), default symbol `ج.م` (EGP), configurable.

---

## 4. Spacing, Radius, Elevation

### 4.1 Spacing scale (dp)

`xs 4` · `sm 8` · `md 12` · `lg 16` · `xl 24` · `xxl 32` · `xxxl 48`

- Screen horizontal padding: **16**
- Gap between cards: **12**
- Card inner padding: **16**
- Section gap: **24**

### 4.2 Corner radius

| Token | Value | Usage |
|---|---|---|
| `radiusSm` | 8 | Chips, small badges, snackbars |
| `radiusMd` | 12 | Buttons, inputs, list tiles |
| `radiusLg` | 16 | Cards, dialogs |
| `radiusXl` | 24 | Bottom sheets (top corners), hero stat card |
| `radiusFull` | 999 | Avatars, pills, FAB (if circular) |

### 4.3 Elevation (soft, light-theme shadows)

| Level | Shadow | Usage |
|---|---|---|
| 0 | none, 1px `border` | Default cards (flat, bordered) |
| 1 | `0 1 3 rgba(27,33,48,.06)` | Raised cards, list items on press |
| 2 | `0 4 12 rgba(27,33,48,.08)` | App bar on scroll, floating bars |
| 3 | `0 8 24 rgba(27,33,48,.12)` | Dialogs, bottom sheets, FAB |

Prefer **border over shadow** for cards to keep the UI crisp and low-cost on weak devices.

---

## 5. Iconography

- **Set:** Material Symbols Rounded (or `Icons.*_rounded`). One consistent weight (400).
- **Sizes:** 20 (inline), 24 (default), 32 (feature/empty states), 48+ (empty illustrations).
- **Color:** `textSecondary` by default, `primary` when active/selected.
- **Icon container:** 40×40, `radiusMd`, background = semantic tint, icon = semantic color.

| Area | Icon |
|---|---|
| Dashboard | `space_dashboard_rounded` |
| Members | `groups_rounded` |
| Memberships | `card_membership_rounded` |
| Finance | `account_balance_wallet_rounded` |
| Settings / Backup | `settings_rounded` / `cloud_upload_rounded` |
| Add | `add_rounded` |
| Renew | `autorenew_rounded` |
| Pause | `pause_circle_rounded` |
| Attendance | `how_to_reg_rounded` |
| Search | `search_rounded` |
| Phone / WhatsApp | `call_rounded` |
| Export | `ios_share_rounded` |
| Lock | `lock_rounded` / `fingerprint_rounded` |

---

## 6. Components

### 6.1 Buttons

All buttons: height **52**, min width 64, `radiusMd (12)`, `labelLarge`, horizontal padding 24, icon gap 8.

| Type | Background | Text/Icon | Border | Usage |
|---|---|---|---|---|
| **Primary (Filled)** | `primary` | `onPrimary` | none | Main action per screen: Save, Renew, Add Payment |
| **Secondary (Tonal)** | `primaryLight` | `primaryDark` | none | Supporting action: Add Note, Export |
| **Outlined** | transparent | `secondary` | 1.5px `borderStrong` | Cancel, Back, Filters |
| **Text** | transparent | `primary` | none | Low-emphasis links: See all, Clear |
| **Destructive** | `error` | `#FFFFFF` | none | Delete member, Reset data (always behind a confirm dialog) |
| **Destructive Outlined** | transparent | `error` | 1.5px `error` | Soft delete options |

**States**

| State | Treatment |
|---|---|
| Pressed | Darken 8% (`primaryDark` for primary), ripple `primary` @ 12% |
| Disabled | Background `surfaceVariant`, text `textDisabled`, no ripple |
| Loading | Replace label with 20dp `CircularProgressIndicator` (stroke 2.5), keep button width, block taps |
| Focused (keyboard) | 2px `primary` outer ring, 2px offset |

**Other button forms**

- **FAB:** 56×56 (or Extended, height 56), `primary`, icon `onPrimary`, `radiusLg (16)`, elevation 3. Position: bottom-end (left in RTL). Used on Members (Add member) and Finance (Add transaction).
- **Icon button:** 48×48 hit area, 24 icon, `textSecondary`.
- **Small button (in-card):** height 40, `labelMedium`-bold 14sp, same colors; e.g., "Renew" on an expiring member card.
- **Button groups:** Two buttons side by side use equal width with a 12 gap. The primary is on the reading-start side (right in RTL).

### 6.2 Text Fields

- Height 56, `radiusMd`, fill `surfaceVariant`, 1px `border` outline.
- Label floats above (`textSecondary`, 14), input `bodyLarge`.
- Focused: 2px `primary` border, fill `surface`.
- Error: 1.5px `error` border, helper text `error` 12sp with an icon.
- Disabled: fill `#F5F6F8`, text `textDisabled`.
- Prefix icons in `textSecondary`; suffix clear button when text exists.
- **Phone field:** LTR number direction inside RTL layout, numeric keyboard.
- **Money field:** numeric keyboard, thousands separator, currency suffix.
- **Search field:** height 48, `radiusFull`, fill `surface`, 1px `border`, search icon at start, clear icon at end.
- **Dropdown / Selector:** same style as text field with `expand_more_rounded` suffix; opens a bottom sheet list on mobile.
- **Date picker:** Material date picker themed with `primary`; field shows formatted date with `calendar_month_rounded`.

### 6.3 Cards

- Background `surface`, `radiusLg (16)`, 1px `border`, padding 16, elevation 0.
- Tappable cards: ink ripple, scale 0.98 on press (100ms).
- **Stat card (dashboard):** icon container (top), big value (`headlineMedium`), label (`bodyMedium`, `textSecondary`), optional delta chip.
- **Hero stat card (net profit):** `radiusXl`, gradient `primary → #FF8A47` (top-start to bottom-end), text `onPrimary`. The only gradient in the app.

### 6.4 Member List Tile

```
[Avatar 48]  Name (titleMedium)                 [Status chip]
             Phone · Package name (bodyMedium, textSecondary)
             Ends: 12 Nov 2026  ·  23 days left
```

- Avatar: circular photo, or initials on `primaryLight` with `primaryDark` text when no photo.
- Divider: 1px `border`, inset to align with text.
- Swipe actions (optional): start = Call (success), end = Renew (primary).

### 6.5 Status Chips / Badges

- Height 28, horizontal padding 10, `radiusFull`, `labelMedium`.
- Background = semantic tint, text + leading 16dp icon = semantic color (see 2.4).
- **Payment chips:** مدفوع (success) · مدفوع جزئياً (warning) · غير مدفوع (error).

### 6.6 Filter Chips

- Height 36, `radiusFull`, 1px `border`, text `textSecondary`.
- Selected: fill `primaryLight`, border `primary`, text `primaryDark`, leading check icon.
- Horizontal scroll row under the search field: الكل · نشط · ينتهي قريباً · منتهي · موقوف.

### 6.7 Navigation

**Bottom navigation bar** (4 destinations; RTL order follows reading direction)

1. الرئيسية (Dashboard) 2. المشتركين (Members) 3. الباقات (Memberships) 4. الحسابات (Finance)

- Height 72, background `surface`, top border 1px `border`.
- Selected: icon in a `primaryLight` pill (64×32, `radiusFull`) with `primary` icon, label `primary` bold 12sp.
- Unselected: icon + label `textSecondary`.
- Settings/Backup is reached from an icon in the Dashboard app bar (gear), keeping the bottom bar simple.

**App bar**

- Background `surface`, no elevation (elevation 2 only when scrolled), height 64.
- Title `titleLarge`, `textPrimary`. Back button follows RTL (arrow flips).
- Actions: icon buttons (search, filter, export, settings).

### 6.8 Dialogs and Sheets

- **Confirm dialog:** `radiusLg`, padding 24, title `titleLarge`, body `bodyLarge` `textSecondary`, actions end-aligned: Text/Outlined cancel + Filled (or Destructive) confirm. Max width 340.
- **Bottom sheet:** `radiusXl` top corners, drag handle 40×4 `borderStrong`, padding 16–24, scrim `overlay`. Used for: renew membership, add payment, pick package, filters, quick member actions.
- **Destructive confirmations** must name the thing being deleted ("حذف المشترك أحمد؟") and use the Destructive button.

### 6.9 Feedback

- **Snackbar:** floating, `radiusSm`, margin 16, background `secondary`, text white, optional action in `primaryLight`. Success/error use a leading colored icon (not a full colored background).
- **Banner (inline):** tint background + 1px semantic border + icon, `radiusMd`, padding 12. E.g., "5 اشتراكات تنتهي خلال 3 أيام" (warning).
- **Loading:** skeleton shimmer (base `#EEF0F4`, highlight `#F9FAFB`) for lists and stat cards; centered spinner only for short blocking actions.
- **Empty state:** 64dp icon in `primaryLight` circle (112), title `titleMedium`, one-line hint `textSecondary`, a primary button with the obvious next step (e.g., "إضافة أول مشترك").
- **Error state:** `error_outline_rounded` in error tint, message, "Retry" Outlined button.

### 6.10 Lists, Tables, Dividers

- Lists use 1px `border` dividers, no zebra striping.
- **Finance transaction row:** leading icon container (income = success tint / expense = error tint), title + category/method, trailing amount (`titleMedium`, tabular figures) with `+` success / `−` error color, date underneath.
- **Table header (reports/export preview):** `surfaceVariant`, `labelMedium` bold, `textSecondary`.

### 6.11 Switch, Checkbox, Radio, Segmented

- Active color `primary`, inactive track `borderStrong`, thumb white.
- Checkbox radius 6, 22×22 visual with 48 hit area.
- Segmented control (e.g., Day / Month / Year, Income / Expense): height 44, `radiusFull`, track `surfaceVariant`, selected segment `surface` with elevation 1 and `primary` bold text.

### 6.12 Charts (fl_chart)

- White card, title top, legend below with 10dp colored dots.
- Line/bar thickness: line 3, bars width 16 with top radius 6.
- Grid: horizontal only, `border` color, dashed `4,4`.
- Axis labels `labelMedium`, `textSecondary`. Touch tooltip: `secondary` background, white text, `radiusSm`.

---

## 7. Screens

### 7.1 Dashboard (لوحة التحكم)

Scroll order:

1. **App bar:** greeting + gym name, gear icon (settings/backup).
2. **Expiry alert banner** (warning) if any memberships end within N days; tap opens the filtered list.
3. **2×2 stat grid:** Active members (success), Expiring soon (warning), New this month (info), Today's check-ins (primary).
4. **Hero card:** Net profit this month, with Revenue and Expenses as two sub-values underneath, inside the card.
5. **Revenue vs Expenses chart:** bar chart with Day / Week / Month segmented control.
6. **Expiring soon list:** the next 5 members, each with an inline small "Renew" button; "عرض الكل" text button.
7. **Quick actions row:** إضافة مشترك · تسجيل حضور · تسجيل دفعة · مصروف جديد (icon-over-label tiles, 72 high, tonal).

### 7.2 Members (المشتركين)

- **Top:** Search field (name/phone) + filter chips row (status).
- **List:** Member list tiles (6.4). Pull-to-refresh. Sticky count header: "128 مشترك".
- **FAB:** Add member.
- **Add/Edit Member form:** single scroll page with sections:
  - Photo: 96dp circular picker (camera / gallery bottom sheet).
  - Basic: name, phone.
  - Body info: age, weight (kg), height (cm), in a 3-column row.
  - Notes: multi-line field.
  - Sticky bottom bar: Save (primary) + Cancel (outlined).
- **Member Details:**
  - Header: large avatar (80), name, status chip, phone with Call/WhatsApp icon buttons.
  - **Action row:** تجديد (primary) · إيقاف مؤقت (tonal) · تسجيل حضور (tonal).
  - **Body stats** card: age / weight / height as three mini stat cells.
  - **Current membership card:** package, start → end, progress bar (primary; warning when <20% left, error when expired), remaining days or visits, paid / remaining amount.
  - **Tabs:** الاشتراكات (history) · الحضور (attendance) · المدفوعات · الملاحظات.
  - Attendance tab: month calendar with attended days marked by `primary` dots + list below.

### 7.3 Memberships (الباقات)

- **List of package cards:** name, price (headlineMedium), duration or visit count, small badge (مدة / زيارات), edit icon.
- **FAB:** إنشاء باقة.
- **Create/Edit Package:** name, price, type selector (Segmented: بالمدة / بعدد الزيارات), duration (days/months) or visit count, active toggle.
- **Renew flow (bottom sheet):** pick package → start date (default: today or the day after current end) → amount paid (default full) → payment method chips (نقدي · تحويل · محفظة إلكترونية) → remaining amount shown live → primary "تأكيد التجديد".
- **Pause flow:** reason (optional), pause date, confirm; the member chip becomes "موقوف" (paused tint). Resume button shown on the member page.

### 7.4 Finance (الحسابات)

- **Header:** month selector (chevrons + month name) and a three-cell summary: Revenue (success) · Expenses (error) · Net (primary).
- **Segmented tabs:** الكل · الإيرادات · المصروفات.
- **Transaction list:** grouped by day with sticky day headers and daily totals.
- **FAB (extended):** "إضافة" opens a sheet with two choices: تسجيل دفعة / تسجيل مصروف.
- **Add expense form:** category chips (إيجار · كهرباء · مياه · صيانة · أخرى), amount, date, method, note.
- **Add payment:** choose member → amount → method → shows remaining balance after payment.
- **Members with balances:** a list card showing who owes money (error-colored amount), tap to collect.
- **Reports:** daily / monthly view with the chart and an Export (PDF / CSV) outlined button.
- Method icons: cash `payments_rounded`, transfer `swap_horiz_rounded`, e-wallet `account_balance_wallet_rounded`. Method is optional metadata only.

### 7.5 Settings, Security & Backup

- **Login / Lock screen:** centered logo (72), title, PIN dots (4–6, 16dp, filled `primary`), custom numeric keypad (key 72×72 `radiusFull`, `surface`, 1px `border`, tap fills `primaryLight`), fingerprint key at the corner, error shake + `error` dots on a wrong PIN.
- **Settings list** (grouped cards with icon containers):
  - الأمان: change PIN, fingerprint toggle, auto-lock timeout.
  - البيانات: backup now, restore from backup, export members (CSV/PDF).
  - التنبيهات: days before expiry, notification toggle.
  - عن التطبيق: version.
- **Backup/Restore:** status card showing last backup time (success check). Primary "نسخ احتياطي الآن". Restore is Outlined and always behind a warning dialog ("سيتم استبدال البيانات الحالية").
- **Danger zone** (if any reset exists): bordered `error` card at the bottom with a Destructive Outlined button.

---

## 8. Motion

| Interaction | Duration | Curve |
|---|---|---|
| Button press / card tap scale | 100 ms | `easeOut` |
| Page transition (go_router) | 250 ms | `easeInOutCubic`, shared axis (horizontal, RTL-aware) |
| Bottom sheet / dialog | 250 ms | `easeOutCubic` |
| Chip / switch / tab change | 180 ms | `easeInOut` |
| Chart load | 600 ms | `easeOutCubic` |
| Counter numbers on dashboard | 500 ms count-up (first load only) | `easeOut` |

Keep motion subtle; respect `MediaQuery.disableAnimations`. Haptic: light impact on check-in and successful renew; medium on destructive confirm.

---

## 9. Layout and Responsiveness

- **Primary target:** phones, 360–430 dp wide, portrait.
- **Tablet (≥ 600 dp):** replace bottom navigation with `NavigationRail` (start side), constrain content to max 900 dp, Dashboard stat grid becomes 4 columns, Members becomes master-detail (list + details).
- **Safe areas:** respect insets; sticky bottom bars sit above the system navigation.
- **Keyboard:** forms scroll and keep the focused field visible; sticky action bar lifts above the keyboard.
- **Text scale:** support up to 1.3×; layouts must wrap rather than clip.

---

## 10. Accessibility

- Touch targets ≥ 48 dp.
- Every icon-only button has a `tooltip`/`Semantics` label (in Arabic).
- Status is conveyed by icon + text, not color alone.
- Focus order follows the RTL reading order.
- Error messages are specific ("رقم الهاتف يجب أن يكون 11 رقماً"), shown inline and announced.
- Contrast ratios as listed in 2.6.

---

## 11. Content and Tone (Arabic)

- Short, direct, friendly; Egyptian-neutral Modern Standard Arabic for labels, no slang in UI chrome.
- Action buttons are verbs: "حفظ", "تجديد", "إضافة", "تأكيد".
- Dates shown as `12 نوفمبر 2026`; relative hints for urgency: "ينتهي بعد 3 أيام", "انتهى منذ 5 أيام".
- Empty states encourage the next step; errors say what to do next.

---

## 12. Flutter Implementation Reference

### 12.1 `app_colors.dart`

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFFF26B1D);
  static const primaryDark = Color(0xFFC9520D);
  static const primaryLight = Color(0xFFFFE6D6);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF1F2A44);
  static const secondaryLight = Color(0xFFE8EBF2);
  static const onSecondary = Color(0xFFFFFFFF);

  // Neutrals
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F6);
  static const border = Color(0xFFE3E6EC);
  static const borderStrong = Color(0xFFC9CED8);
  static const textPrimary = Color(0xFF1B2130);
  static const textSecondary = Color(0xFF5B6475);
  static const textDisabled = Color(0xFF9AA1AF);

  // Semantic
  static const success = Color(0xFF1E9E5A);
  static const successTint = Color(0xFFE3F6EC);
  static const warning = Color(0xFFE59A0B);
  static const warningTint = Color(0xFFFFF3D6);
  static const error = Color(0xFFD93C3C);
  static const errorTint = Color(0xFFFDE7E7);
  static const info = Color(0xFF2F6FDE);
  static const infoTint = Color(0xFFE4EEFD);
  static const paused = Color(0xFF7A52CC);
  static const pausedTint = Color(0xFFEEE8FA);

  static const heroGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [primary, Color(0xFFFF8A47)],
  );
}
```

### 12.2 `app_spacing.dart`

```dart
abstract final class AppSpacing {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0, xxxl = 48.0;
}

abstract final class AppRadius {
  static const sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, full = 999.0;
}
```

### 12.3 `app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static const _fontFamily = 'Cairo';

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: AppColors.secondary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorTint,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
    );

    final shape12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));

    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ).apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: TextStyle(
            fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceVariant,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: shape12,
          textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
          shape: shape12,
          textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          shape: shape12,
          textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textDisabled),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.error, 1.5),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
        showCheckmark: true,
        checkmarkColor: AppColors.primaryDark,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: _fontFamily,
              fontSize: 12,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
            )),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
        contentTextStyle: const TextStyle(fontFamily: _fontFamily, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : AppColors.borderStrong),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
        side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryLight,
      ),
    );
  }
}
```

### 12.4 `main.dart` (light only, RTL Arabic)

```dart
MaterialApp.router(
  theme: AppTheme.light,
  themeMode: ThemeMode.light,   // light only, no darkTheme
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  routerConfig: appRouter,
);
```

Also lock the status bar for light surfaces:

```dart
SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: AppColors.surface,
  systemNavigationBarIconBrightness: Brightness.dark,
));
```

### 12.5 Suggested folder placement (clean architecture)

```
lib/
  core/
    theme/
      app_colors.dart
      app_spacing.dart
      app_theme.dart
    widgets/                  # shared design-system widgets
      app_button.dart         # primary / tonal / outlined / destructive variants + loading
      app_text_field.dart
      status_chip.dart
      stat_card.dart
      member_tile.dart
      empty_state.dart
      confirm_dialog.dart
  features/
    dashboard/ members/ memberships/ finance/ settings/
      presentation/ (pages, widgets, cubit)
```

---

## 13. Quick Reference Cheat Sheet

| Item | Value |
|---|---|
| Primary | `#F26B1D` |
| Navy (secondary) | `#1F2A44` |
| Background | `#F7F8FA` |
| Card | `#FFFFFF`, 16 radius, 1px `#E3E6EC` |
| Button | 52 high, 12 radius, 16 bold |
| Input | 56 high, 12 radius, fill `#F1F3F6` |
| Screen padding | 16 |
| Font | Cairo |
| Active / Expiring / Expired / Paused | green / amber / red / purple |
| Income / Expense | `#1E9E5A` / `#D93C3C` |
| Theme | **Light only** |
