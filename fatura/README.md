# فاتورة (Fatura)

**POS + Invoices + Inventory** — تطبيق إدارة المبيعات والفواتير والمخزون للبيزنس الميكرو.

## الشركة
Codester-inc

## Stack
- **Framework:** Flutter 3.47+ / Dart 3.13+
- **Database:** Drift (SQLite) — offline-first
- **State:** Riverpod 2.x
- **Routing:** GoRouter
- **Architecture:** Clean Architecture + MVVM

## Project Structure
```
fatura/
├── lib/
│   ├── core/
│   │   ├── constants/     # AppColors, AppStrings, AppSizes
│   │   ├── theme/         # Dark theme, responsive layout
│   │   ├── database/      # Drift tables, DAOs, database
│   │   ├── router/        # GoRouter with custom transitions
│   │   └── utils/         # Formatters, validators, PIN hasher
│   ├── features/
│   │   ├── auth/          # PIN login
│   │   ├── onboarding/    # First-run wizard
│   │   ├── pos/           # Quick sale / barcode
│   │   ├── invoices/      # Invoice CRUD + share + print
│   │   ├── inventory/     # Products CRUD + barcode + low stock
│   │   ├── reports/      # Daily/monthly charts
│   │   ├── users/        # User management + permissions
│   │   └── settings/     # App settings
│   ├── data/             # Data layer (repositories impl)
│   ├── domain/           # Domain layer (entities, usecases)
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## Phase 1 — Foundation (Complete)
- **T-001:** Flutter project init + all packages
- **T-002:** Drift database (7 tables, 7 DAOs, codegen)
- **T-003:** Dark theme + design system + responsive layout
- **T-004:** GoRouter with 4 custom transition types

## Running
```bash
flutter pub get
dart run build_runner build
flutter run
```

## Brand Colors
| Color | Hex |
|-------|-----|
| Background | #0a0e1a |
| Cyan Accent | #00d9ff |
| Purple Accent | #6c5ce7 |