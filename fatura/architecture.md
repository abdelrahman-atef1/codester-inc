# Architecture Document — فاتورة (Fatura)

**الشركة:** Codester-inc
**المشروع:** فاتورة — POS + فواتير + مخزون للبيزنس الميكرو
**أُعد بواسطة:** Chief Architect — claude-opus-4-6-thinking (agy)
**التاريخ:** 4 سبتمبر 2026

---

## 1. Stack Selection

| Component | Technology | Reason |
|-----------|-----------|--------|
| **Framework** | Flutter (latest) | Mobile-first، cross-platform، RTL support |
| **Language** | Dart | Flutter native |
| **Local Database** | Drift (SQLite-based) | Actively maintained، type-safe، reactive queries |
| **State Management** | Riverpod 2.x | Compile-safe، testable، no boilerplate |
| **Architecture** | Clean Architecture + MVVM | Separation of concerns، testable |
| **Routing** | GoRouter | Declarative، deep linking support |

> **ملاحظة:** Isar و Hive abandoned — Drift هو الخيار الأفضل لـ 2026.

---

## 2. Database Schema (Drift/SQLite)

### Table: stores (المتجر)
```sql
id: INTEGER PRIMARY KEY
name: TEXT NOT NULL
type: TEXT (كشك/متجر/صناع يدوي/أخرى)
address: TEXT
phone: TEXT
currency: TEXT DEFAULT 'EGP'
language: TEXT DEFAULT 'ar'
tax_enabled: BOOLEAN DEFAULT false
tax_rate: REAL DEFAULT 0
logo_path: TEXT
created_at: DateTime
updated_at: DateTime
```

### Table: users (الموظفين)
```sql
id: INTEGER PRIMARY KEY
store_id: INTEGER REFERENCES stores(id)
name: TEXT NOT NULL
pin_code: TEXT NOT NULL (hashed)
role: TEXT NOT NULL -- owner, pos_clerk, inventory_manager, viewer
permissions: TEXT -- JSON array of permissions
is_active: BOOLEAN DEFAULT true
created_at: DateTime
last_login: DateTime
```

### Table: products (المنتجات)
```sql
id: INTEGER PRIMARY KEY
name: TEXT NOT NULL
barcode: TEXT
price: REAL NOT NULL
cost: REAL
quantity: INTEGER NOT NULL DEFAULT 0
min_quantity: INTEGER DEFAULT 5
category: TEXT
unit: TEXT DEFAULT 'قطعة'
image_path: TEXT
created_at: DateTime
updated_at: DateTime
```

### Table: invoices (الفواتير)
```sql
id: INTEGER PRIMARY KEY
invoice_number: TEXT NOT NULL UNIQUE
store_id: INTEGER REFERENCES stores(id)
user_id: INTEGER REFERENCES users(id)
customer_name: TEXT
customer_phone: TEXT
subtotal: REAL NOT NULL
tax: REAL DEFAULT 0
discount: REAL DEFAULT 0
total: REAL NOT NULL
payment_method: TEXT -- cash, card, wallet
amount_paid: REAL
change: REAL
status: TEXT -- draft, completed, refunded
created_at: DateTime
```

### Table: invoice_items (عناصر الفاتورة)
```sql
id: INTEGER PRIMARY KEY
invoice_id: INTEGER REFERENCES invoices(id) ON DELETE CASCADE
product_id: INTEGER REFERENCES products(id)
name: TEXT NOT NULL
price: REAL NOT NULL
quantity: INTEGER NOT NULL
total: REAL NOT NULL
```

### Table: activity_log (سجل النشاط)
```sql
id: INTEGER PRIMARY KEY
user_id: INTEGER REFERENCES users(id)
action: TEXT NOT NULL -- sale, edit_product, add_product, login, etc
entity_type: TEXT -- invoice, product, user
entity_id: INTEGER
details: TEXT
created_at: DateTime
```

### Table: settings (الإعدادات)
```sql
id: INTEGER PRIMARY KEY
key: TEXT NOT NULL UNIQUE
value: TEXT
```

---

## 3. Architecture Pattern — Clean Architecture + MVVM

```
lib/
├── core/                    # Shared infrastructure
│   ├── constants/
│   ├── theme/               # Dark/light theme + Codester colors
│   ├── utils/
│   └── database/            # Drift database setup
├── features/                # Feature modules
│   ├── auth/                # PIN login + roles
│   ├── onboarding/          # First-run wizard
│   ├── pos/                 # Sales / Quick sale
│   ├── invoices/            # Invoice CRUD + share + print
│   ├── inventory/           # Products CRUD + barcode
│   ├── reports/             # Daily/monthly reports
│   ├── users/               # User management + permissions
│   └── settings/            # App settings
├── data/                    # Data layer
│   ├── repositories/
│   └── datasources/
├── domain/                  # Domain layer
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── main.dart
```

Each feature module:
- `presentation/` — screens + widgets + viewmodels (Riverpod providers)
- `domain/` — entities + usecases
- `data/` — repository impl + datasource

---

## 4. Offline-First Strategy

- **Local DB:** Drift (SQLite) — كل البيانات محلياً
- **No server required:** التطبيق شغال 100% offline
- **Sync (optional):** لو المستخدم ربط Google Drive، يعمل backup تلقائي
- **Conflict resolution:** Last-write-wins (بسيط، مناسب للبيزنس الميكرو)

---

## 5. Barcode Scanning

| Package | License | Status |
|---------|---------|--------|
| **mobile_scanner** | MIT | Active, fast, ML Kit based |

```yaml
dependencies:
  mobile_scanner: ^latest
```

- Android: CameraX + ML Kit
- iOS: AVFoundation + Vision
- No Google Services required (works on Huawei devices)

---

## 6. Bluetooth Printing

| Package | License | Status |
|---------|---------|--------|
| **flutter_receipt_printer** | MIT | Active, ESC/POS + TSC |

```yaml
dependencies:
  flutter_receipt_printer: ^1.0.0
```

Features:
- ESC/POS commands (text, bold, align, QR, barcode)
- 58mm + 80mm thermal printers
- Android: Classic Bluetooth (RFCOMM/SPP)
- iOS/macOS/Windows/Linux: BLE
- Auto-reconnect to last printer
- Unicode support (Arabic ✅)

---

## 7. PDF Generation

| Package | License | Status |
|---------|---------|--------|
| **pdf + printing** | Apache 2.0 | Active, by DavBfr |

```yaml
dependencies:
  pdf: ^latest
  printing: ^latest
```

- Generate invoice PDF
- Print via system print dialog
- Share via share_plus

---

## 8. Sharing

| Package | License | Status |
|---------|---------|--------|
| **share_plus** | BSD | Active, official Flutter team |

```yaml
dependencies:
  share_plus: ^latest
```

- Share invoice as image (JPEG) or PDF
- Opens WhatsApp/SMS/Telegram natively

---

## 9. Backup Strategy (Google Drive)

| Package | License | Status |
|---------|---------|--------|
| **googleapis** + **google_sign_in** | BSD | Active |

Strategy:
- Backup = SQLite DB file → uploaded to Google Drive
- Auto-backup: daily/weekly (configurable)
- Manual backup: button in settings
- Restore: download DB file → replace local
- File: `fatura-backup-YYYY-MM-DD.db`
- Folder: `Codester-inc/Fatura/Backups/`

Cost: $0 (Google Drive API free tier = 1B requests/day)

---

## 10. Charts (Reports)

| Package | License | Status |
|---------|---------|--------|
| **fl_chart** | Apache 2.0 | Active, beautiful |

```yaml
dependencies:
  fl_chart: ^latest
```

- Bar chart: daily sales
- Line chart: monthly trend
- Pie chart: top products

---

## 11. Roles & Permissions

| Role | POS | Invoices | Inventory | Reports | Users | Settings |
|------|-----|----------|-----------|---------|-------|----------|
| Owner | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| POS Clerk | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Inventory Manager | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Viewer | ❌ | ❌ | ❌ | ✅ (read) | ❌ | ❌ |

- Login: PIN code (4-6 digits)
- Owner can assign multiple permissions per user
- Permissions checked per screen via Riverpod guard

---

## 12. File Structure

```
fatura/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── app_sizes.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── dark_theme.dart
│   │   ├── database/
│   │   │   ├── database.dart
│   │   │   ├── tables.dart
│   │   │   └── daos/
│   │   ├── utils/
│   │   │   ├── formatters.dart
│   │   │   └── validators.dart
│   │   └── router/
│   │       └── app_router.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   └── widgets/
│   │   │   └── providers/
│   │   ├── onboarding/
│   │   ├── pos/
│   │   ├── invoices/
│   │   ├── inventory/
│   │   ├── reports/
│   │   ├── users/
│   │   └── settings/
│   ├── data/
│   ├── domain/
│   └── main.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/ (Cairo/Tajawal for Arabic)
├── test/
├── pubspec.yaml
└── README.md
```

---

## 13. Cost Analysis

| Item | Cost | Notes |
|------|------|-------|
| Flutter SDK | $0 | Open source |
| Drift (SQLite) | $0 | Open source |
| Riverpod | $0 | Open source |
| mobile_scanner | $0 | Open source |
| flutter_receipt_printer | $0 | Open source |
| pdf + printing | $0 | Open source |
| share_plus | $0 | Open source |
| fl_chart | $0 | Open source |
| googleapis (Drive) | $0 | Free tier |
| Google Play Developer | $25 | One-time fee |
| App Store Developer | $99/year | Optional (later) |
| Hosting/Server | $0 | No server needed |
| **Total (MVP)** | **$25** | One-time Google Play fee |

> **التكلفة التشغيلية: $0/شهر** — كل حاجة local أو free tier.

---

## 14. Key Decisions

1. **Drift over Isar/Hive** — Isar abandoned, Hive v2 deprecated. Drift = SQLite + type safety + reactive.
2. **Riverpod over Provider/Bloc** — Compile-safe, less boilerplate, better testing.
3. **mobile_scanner over barcode_scan2** — barcode_scan2 abandoned. mobile_scanner = ML Kit, faster, maintained.
4. **flutter_receipt_printer over bluetooth_print** — bluetooth_print outdated. flutter_receipt_printer = modern, ESC/POS, active.
5. **GoRouter over Navigator 2.0** — Declarative, simpler, deep linking.
6. **Clean Architecture** — Feature-based modules, testable, scalable.
7. **PIN code auth** — No email/password needed. Simple for micro business.
8. **Arabic-first** — RTL by default, Cairo/Tajawal fonts, Arabic UI.

---

## 15. Packages Summary (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  drift: ^latest
  sqlite3_flutter_libs: ^latest
  riverpod: ^latest
  flutter_riverpod: ^latest
  go_router: ^latest
  mobile_scanner: ^latest
  flutter_receipt_printer: ^1.0.0
  pdf: ^latest
  printing: ^latest
  share_plus: ^latest
  fl_chart: ^latest
  googleapis: ^latest
  google_sign_in: ^latest
  path_provider: ^latest
  path: ^latest
  intl: ^latest

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^latest
  build_runner: ^latest
  riverpod_generator: ^latest
```