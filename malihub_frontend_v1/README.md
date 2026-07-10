# Malihub — Flutter Frontend

A personal finance app built with Flutter, featuring a custom design system, hand-drawn data visualizations, and a complete screen flow from splash to analytics.

## Design System

The app uses a curated palette built around forest green (`#1F8A4C`), with a deeper forest shade for depth, muted gold for milestones and completed goals, ink-green text in place of flat black, and brick red for expense indicators.

A circular progress **ring** serves as the signature visual motif across Budget, Savings, and Analytics, giving "Hub" a tangible shape rather than treating it as purely nominal. See `lib/theme/app_colors.dart` and `lib/theme/app_text.dart` for the full palette and type scale.

## Features

### Screens
- **Splash** — branded launch animation on app startup
- **Onboarding** — 3-slide first-run intro with custom illustrations
- **Login / Registration / Forgot Password** — complete auth flow
- **Dashboard** — overview with avatar-linked profile access
- **Transactions** — full history with tap-to-detail navigation
- **Transaction Detail** — view, edit, or delete any transaction
- **Budget Planner** — category-based budget allocation with progress rings
- **Analytics / Insights** — spending breakdown via hand-drawn donut chart and month-over-month comparison; accessible via bottom navigation
- **Profile** — settings screen reached through the Dashboard avatar
- **Notifications** — budget alerts, goal milestones, and spending tips; reached via the bell icon

### Navigation
Bottom navigation with four tabs: Home, Transactions, Insights, and Budget.

### Visual System
- `ring_progress.dart` — reusable circular progress indicator used across budgets, savings, and category breakdowns
- `donut_chart.dart` — multi-slice ring chart for Analytics, drawn with `CustomPainter`
- `malihub_logo.dart` — shared brand mark, consistent with the app launcher icon

## App Icon

The wallet mark from the Login header is used as the Android launcher icon. Setup steps are in `android_app_icon/README.md`:

1. Copy the generated PNGs into `android/app/src/main/res/mipmap-*/`
2. Set the color value in the project config
3. Run `flutter clean` and rebuild

The README also covers Android's adaptive icon system (three PNGs per screen density) and LDPlayer icon caching behavior.

A flat 1024×1024 master PNG is included for iOS icon generation (requires Xcode on macOS).

## Running Locally

```bash
flutter pub get
flutter run
```

No additional dependencies are required — all charts and rings are implemented with Flutter's `CustomPainter`, so no external chart packages are needed.

## Project Structure

```
lib/
  main.dart                        # Entry point; routes to Splash
  theme/
    app_colors.dart                # Palette definitions
    app_text.dart                  # Type scale, spacing, shadows
    app_theme.dart                 # ThemeData
  widgets/
    malihub_logo.dart              # Brand mark
    ring_progress.dart             # Circular progress ring
    donut_chart.dart               # Multi-slice ring chart
    app_text_field.dart
    stat_tile.dart
    malihub_bottom_nav.dart        # 4-tab navigation
  screens/
    splash_screen.dart
    onboarding_screen.dart
    login_screen.dart
    forgot_password_screen.dart
    registration_screen.dart
    main_shell.dart                # Bottom-nav container
    dashboard_screen.dart
    transactions_screen.dart
    transaction_detail_screen.dart
    analytics_screen.dart
    budget_planner_screen.dart
    profile_screen.dart
    notifications_screen.dart
android_app_icon/                   # Launcher icon assets and setup guide
```

## Backend Integration

Screens currently using mock data include `// TODO` comments specifying the expected endpoint (method, path, and request/response shape). Search `lib/` for `TODO` to locate all integration points.

Notable considerations:

- **Category Budgets** (`budget_planner_screen.dart`) assumes a budget supports multiple category allocations. Confirm the budget-category cardinality (single category vs. join table) with your backend team before wiring up real data.
- **Notifications** tapping does not currently deep-link. Whether it should depends on the open question of adding `budget_id`/`goal_id` columns to the notification table.
- **Analytics** expects a category-aggregation endpoint (e.g., `GET /api/transactions/summary`) that may not exist in the current API surface. This is worth raising with the backend team as it extends beyond the original scope.

Once your team finalizes the endpoint contracts, the mock data can be replaced with live API calls.
