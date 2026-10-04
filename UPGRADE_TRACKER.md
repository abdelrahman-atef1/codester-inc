# Codester-inc — App Upgrade Tracker

> Last updated: 2026-10-03
> Track all features for both apps. Each task has: status, agent, priority.

## مهامي (Abduu Tasks) — Upgrades

### P0 — Critical (Must have for release)
| ID | Task | Status | Agent | Notes |
|----|------|--------|-------|-------|
| M01 | Zen Focus theme — Readex Pro font, olive/terracotta palette | ✅ done | designer_1 | In Flutter |
| M02 | Professional UI redesign from Stitch | ✅ done | agent_A | 4 screens from Stitch |
| M03 | Local notifications (replace Firebase FCM) | ✅ done | agent_B | flutter_local_notifications |
| M04 | Weekly planning screen (7 days x roles grid) | ✅ done | agent_B | Editable roles, CRUD |
| M05 | Task sync with dispatcher (local API) | ⏳ pending | — | Future task |
| M06 | Task edit/delete for ALL tasks (defaults + custom) | ✅ done | executor | Long press → edit/delete |
| M07 | Time override for default tasks | ✅ done | executor | Works, sorting fixed |
| M08 | Task descriptions on all cards | ✅ done | executor | 13 tasks have descriptions |
| M09 | Gym task 🚴 added | ✅ done | executor | 7:00 AM |
| M10 | Crash fix (package path mismatch) | ✅ done | executor | v1.2.0+3 |

### P1 — Important (Should have)
| ID | Task | Status | Agent | Notes |
|----|------|--------|-------|-------|
| M11 | Swipe gestures (right=done, left=snooze) | ✅ done | executor | Dismissible |
| M12 | Progress bar (daily completion %) | ✅ done | executor | Glass bar |
| M13 | FAB to add custom tasks | ✅ done | executor | Glass FAB |
| M14 | Onboarding screen | ✅ done | executor | Glassmorphism welcome |
| M15 | Theme picker (3 themes switch) | ✅ done | executor | In settings |
| M16 | Push to GitHub | ✅ done | — | abdelrahman-atef1/abduu-tasks |
| M17 | Roles & permissions | ✅ done | agent_E | Editable roles CRUD |
| M18 | Cloud backup (Google Drive) | ⏳ pending | — | User-owned storage |
| M19 | Arabic/English language toggle | ✅ done | agent_J | i18n with ARB files |
| M20 | Multiple currencies | ⏳ pending | — | EGP/SAR/AED/USD |

### P2 — Nice to have
| ID | Task | Status | Agent | Notes |
|----|------|--------|-------|-------|
| M21 | Celebration screen when all done | ✅ done | agent_I | Confetti overlay |
| M22 | Task statistics (weekly/monthly) | ✅ done | agent_I | fl_chart bar chart + streaks |
| M23 | Dark/light mode toggle per theme | ✅ done | agent_I | Dark Zen Focus variant |
| M24 | Custom task emojis picker | ⏳ pending | — | Visual emoji grid |
| M25 | Notification sounds | ⏳ pending | — | Custom per task |

---

## فاتورة (Fatura) — Upgrades

### P0 — Critical (Must have for release)
| ID | Task | Status | Agent | Notes |
|----|------|--------|-------|-------|
| F01 | Professional UI redesign from Stitch | ✅ done | agent_C+D | 4 screens from Stitch |
| F02 | POS dashboard (product grid + cart + checkout) | ✅ done | agent_C | RTL, search, categories, cart |
| F03 | Invoice creation + sharing (WhatsApp/PDF) | ✅ done | agent_C+G | QR code, PDF, WhatsApp share |
| F04 | Inventory management (add/edit/stock) | ✅ done | agent_D | Stock warnings, category chips |
| F05 | Offline-first (Drift/SQLite local DB) | ✅ done | agent_C | 4 tables, Riverpod providers |
| F06 | Barcode scanning | ✅ done | agent_G | mobile_scanner, RTL UI |
| F07 | Bluetooth thermal printing (58mm/80mm) | ✅ done | agent_G | blue_thermal_printer, ESC/POS |
| F08 | Push to GitHub | ✅ done | — | abdelrahman-atef1/fatura |

### P1 — Important (Should have)
| ID | Task | Status | Agent | Notes |
|----|------|--------|-------|-------|
| F09 | Daily sales report | ✅ done | agent_D | KPI cards, bar chart |
| F10 | Monthly report with chart | ✅ done | agent_D | fl_chart, top products |
| F11 | Multi-currency support | ✅ done | agent_J | EGP/SAR/AED/USD/EUR |
| F12 | Arabic/English toggle | ✅ done | agent_J | i18n with ARB files |
| F13 | Roles & permissions (owner/clerk/inventory) | ✅ done | agent_H | PIN login, SHA-256 hashing |
| F14 | Activity log (who sold/edited what) | ✅ done | agent_H | Filter by user/date/action |
| F15 | Google Drive backup | ⏳ pending | — | User-owned storage |
| F16 | Product categories | ✅ done | agent_D | Filter chips in inventory |

### P2 — Nice to have
| ID | Task | Status | Agent | Notes |
|----|------|--------|-------|-------|
| F17 | Customer database | ⏳ pending | — | Repeat customers |
| F18 | Debt tracking (buy now pay later) | ⏳ pending | — | For trusted customers |
| F19 | Expense tracking | ⏳ pending | — | Rent, utilities, supplies |
| F20 | Supplier management | ⏳ pending | — | Reorder from suppliers |
| F21 | Export data to CSV/Excel | ⏳ pending | — | For accounting |
| F22 | Dark mode | ⏳ pending | — | Professional dark theme |

---

## Implementation Order (Parallel Agents)

### Wave 1 (Now — Stitch designs finishing)
- Agent A: مهامي M02 (Stitch design → Flutter implementation)
- Agent B: فاتورة F01 (Stitch design → Flutter implementation)

### Wave 2 (After designs approved)
- Agent C: مهامي M03 (Local notifications) + M04 (Weekly planning)
- Agent D: فاتورة F02 (POS dashboard) + F03 (Invoices) + F04 (Inventory)
- Agent E: مهامي M05 (Dispatcher sync) + F05 (Offline DB)

### Wave 3 (After core features)
- Agent F: مهامي M17-M20 (Roles, backup, i18n, currencies)
- Agent G: فاتورة F06-F08 (Barcode, printing, polish)
- Agent H: فاتورة F09-F16 (Reports, roles, backup, categories)

### Wave 4 (Polish)
- Agent I: مهامي M21-M25 (Celebration, stats, dark/light, emoji picker, sounds)
- Agent J: فاتورة F17-F22 (Customers, debt, expenses, suppliers, export, dark)