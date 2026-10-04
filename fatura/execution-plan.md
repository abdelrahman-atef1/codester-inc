# 📋 Execution Plan — فاتورة (Fatura)

**Team Lead:** claude-opus-4-6-thinking (agy) — Codester-inc
**Date:** 4 سبتمبر 2026
**Project:** فاتورة — POS + فواتير + مخزون للبيزنس الميكرو
**Stack:** Flutter + Drift + Riverpod + Material 3
**Executor:** gemini-3.8-flash-high (agy)
**Reviewer:** claude-sonnet-4-6 (agy)
**DevOps:** Team Lead

---

## 1. MVP Scope (Must Priority Only)

| # | User Story | Scope Item |
|---|-----------|------------|
| 1 | US-001 | Onboarding Wizard (اسم المتجر + نوع + تخطي العنوان) |
| 2 | US-002 | Local-first بدون حساب سحابي إلزامي |
| 3 | US-003 | إنشاء فاتورة + إضافة منتجات + حساب الإجمالي + ضريبة اختيارية |
| 4 | US-006 | POS سريع — Barcode scan → إضافة فورية للسلة |
| 5 | US-007 | طرق الدفع (نقداً/بطاقة/محفظة) + حساب الباقي |
| 6 | US-008 | إضافة منتج للمخزون (اسم/سعر/كمية/باركود) |
| 7 | US-010 | تعديل سعر/كمية منتج موجود |
| 8 | US-011 | تقرير مبيعات يومي (إجمالي + عدد فواتير + أكثر مبيعاً) |
| 9 | US-013 | عربي/إنجليزي + RTL/LTR |
| 10 | US-014 | عملات متعددة (جنيه/ريال/درهم/دولار) |
| 11 | US-015 | Offline-first كامل (كل العمليات تعمل بدون إنترنت) |
| 12 | US-017 | إضافة موظف + PIN code + صلاحيات |
| 13 | US-018 | تخصيص صلاحيات متعددة لكل موظف |
| 14 | US-019 | تعديل/تعطيل صلاحيات موظف |
| 15 | US-020 | واجهة POS Clerk (POS + فواتير فقط) |
| 16 | US-021 | واجهة Inventory Manager (مخزون فقط) |

**ملاحظة:** US-016 (Google Drive Backup) و US-004/005 (مشاركة/طباعة) و US-009 (تنبيهات النفاد) و US-012 (تقرير شهري) = Should priority → Post-MVP.

---

## 2. Sprint Breakdown (4 أسابيع = Sprintين)

### Sprint 1: الأسبوع 1-2 — Foundation + POS + Inventory

> **الهدف:** التطبيق شغال — تقدر تضيف منتج، تبيع، تشوف فاتورة.

| Day | Work |
|-----|------|
| أيام 1-3 | Project setup, Drift DB, Theme, Routing, Onboarding |
| أيام 4-7 | Inventory CRUD + Barcode + POS Quick Sale |
| أيام 8-10 | Payment methods + Invoice creation + Daily report (basic) |
| أيام 11-14 | Integration testing + Sprint 1 review |

### Sprint 2: الأسبوع 3-4 — Roles + Settings + Polish

> **الهدف:** MVP كامل — صلاحيات، لغات، عملات، offline، animations.

| Day | Work |
|-----|------|
| أيام 15-18 | Roles & Permissions + PIN login + Role-based UI |
| أيام 19-21 | Settings (language, currency, store info) |
| أيام 22-25 | Animations (from animation-spec) + Offline-first hardening |
| أيام 26-28 | UAT + Bug fixes + MVP sign-off |

---

## 3. Task List

### Sprint 1 — Foundation + POS + Inventory

| ID | Task | Owner | Estimate | Dependencies |
|----|------|-------|----------|---------------|
| T-001 | Flutter project init + pubspec dependencies + folder structure | Executor | 2h | — |
| T-002 | Drift database setup (tables, DAOs, migrations) | Executor | 6h | T-001 |
| T-003 | App theme (Material 3, dark/light, Codester colors, Cairo/Tajawal fonts) | Executor | 3h | T-001 |
| T-004 | GoRouter setup + route guards skeleton | Executor | 2h | T-001 |
| T-005 | Onboarding Wizard (US-001): store name, type, skip address | Executor | 4h | T-002, T-003 |
| T-006 | Store profile provider + local persistence | Executor | 2h | T-002, T-005 |
| T-007 | Inventory list screen (products list + search) | Executor | 4h | T-002, T-003 |
| T-008 | Add product screen (US-008): name, price, qty, barcode manual | Executor | 3h | T-007 |
| T-009 | Barcode scanner integration (mobile_scanner) | Executor | 3h | T-008 |
| T-010 | Edit product screen (US-010): edit price/qty + reason field | Executor | 2h | T-007, T-008 |
| T-011 | POS screen — product grid/list + barcode scan → cart | Executor | 6h | T-009, T-007 |
| T-012 | Cart logic — add/remove items, qty stepper, total calc | Executor | 4h | T-011 |
| T-013 | Payment method selector (US-007) + change calculation | Executor | 3h | T-012 |
| T-014 | Invoice creation + save (draft/completed) to DB | Executor | 4h | T-013, T-002 |
| T-015 | Daily report screen (US-011): total, invoice count, top products | Executor | 4h | T-014 |
| T-016 | Sprint 1 integration testing + bug fixes | Executor + Reviewer | 4h | T-001→T-015 |
| T-017 | Sprint 1 code review | Reviewer | 3h | T-001→T-015 |

### Sprint 2 — Roles + Settings + Polish

| ID | Task | Owner | Estimate | Dependencies |
|----|------|-------|----------|---------------|
| T-018 | PIN code login screen (US-017) + hashed PIN storage | Executor | 4h | T-002 |
| T-019 | User management screen (add/edit/deactivate) | Executor | 4h | T-018 |
| T-020 | Permissions system (US-018/019) — Riverpod guards per screen | Executor | 5h | T-018, T-019, T-004 |
| T-021 | Role-based navigation (US-020/021) — POS Clerk / Inventory Manager UI | Executor | 3h | T-020 |
| T-022 | Settings screen — language toggle (US-013) AR/EN + RTL/LTR | Executor | 3h | T-003 |
| T-023 | Settings screen — currency selector (US-014) + formatter | Executor | 3h | T-003 |
| T-024 | Store settings edit (name, type, address, phone, tax) | Executor | 2h | T-006 |
| T-025 | Offline-first hardening (US-015) — verify all ops work offline | Executor | 3h | All prior |
| T-026 | Animations integration (from animation-spec) — page transitions, micro-interactions, state transitions | Executor | 6h | T-005→T-021 |
| T-027 | POS-specific animations (cart add fly-to-cart, checkout, success) | Executor | 4h | T-011, T-013 |
| T-028 | UAT testing (full flow: onboarding → sell → report) | Executor + Reviewer | 4h | T-001→T-027 |
| T-029 | Final code review + cleanup | Reviewer | 4h | All tasks |
| T-030 | MVP release build (APK) + sign-off | DevOps | 2h | T-029 |

---

## 4. Critical Path

التسلسل الذي **لا يجوز** الإخلال به:

```
T-001 (Project Init)
  └→ T-002 (Drift DB)
       └→ T-005 (Onboarding)
            └→ T-007 (Inventory List)
                 └→ T-011 (POS Screen)
                      └→ T-012 (Cart Logic)
                           └→ T-013 (Payment)
                                └→ T-014 (Invoice Save)
                                     └→ T-015 (Daily Report)
                                          └→ T-018 (PIN Login)
                                               └→ T-020 (Permissions)
                                                    └→ T-028 (UAT)
                                                         └→ T-030 (Release)
```

**أي تأخير في task من هذا المسار = تأخير مباشر في الـ MVP.** المهام الفرعية (theme, barcode, animations) تعمل بالتوازي ولا توقف هذا المسار.

---

## 5. Milestones

| Milestone | Timing | What's Delivered | Review By |
|-----------|--------|------------------|-----------|
| **M1 — Sprint 1 Review** | نهاية أسبوع 2 | Onboarding + Inventory + POS + Invoice + Daily Report يعملوا E2E | Team Lead + Owner |
| **M2 — Sprint 2 Mid** | منتصف أسبوع 4 | Roles + PIN + Permissions + Settings شغالة | Team Lead |
| **M3 — MVP Sign-off** | نهاية أسبوع 4 | MVP كامل جاهز للـ UAT + APK build | Owner (Go/No-Go) |

---

## 6. Risk Mitigation

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|------------|
| R1 | **mobile_scanner** مشاكل في أجهزة Huawei أو budget phones | Medium | High | Fallback: إدخال باركود يدوي دائماً متاح (T-009 يشمل الـ fallback) |
| R2 | **Drift** تعقيد في migrations بين نسخ الـ schema | Low | Medium | تصميم schema مسبق كامل + migration tests في Sprint 1 |
| R3 | **flutter_receipt_printer** غير مطلوب في MVP لكنه Should — تأجيل آمن | — | — | تم تأجيله للـ Post-MVP (Should priority) |
| R4 | **Animations** تسبب jank على budget phones | Medium | Low | Animation-spec فيه `performanceTier` check — animations تتلغي على low-end |
| R5 | **RTL** مشاكل layout في العربية | Medium | Medium | Cairo/Tajawal fonts + اختبار RTL من Sprint 1 (مش Sprint 2) |
| R6 | **Executor (gemini-3.8-flash)** بطء في فهم Clean Architecture | Medium | Medium | Reviewer (claude-sonnet-4-6) يعمل code review مبكر في Sprint 1 — catch issues early |
| R7 | **Scope creep** — Owner يطلب features إضافية في الـ MVP | High | High | MVP scope مثبت في هذا المستند. أي feature جديدة = Post-MVP backlog. |
| R8 | **Offline edge cases** — بيانات تضيع عند إغلاق مفاجئ | Low | High | Drift auto-commit + WAL mode + crash test في UAT |

---

## 7. Effort Summary

| Sprint | Tasks | Total Hours | Calendar |
|--------|-------|-------------|----------|
| Sprint 1 (Foundation + POS + Inventory) | T-001→T-017 | ~51h dev + 3h review + 4h test = **58h** | أسبوعين |
| Sprint 2 (Roles + Settings + Polish) | T-018→T-030 | ~44h dev + 4h review + 4h UAT + 2h DevOps = **54h** | أسبوعين |
| **Total** | **30 tasks** | **~112h** | **4 أسابيع** |

> ✅ ضمن النطاق المستهدف (3-5 أسابيع).

---

## 8. Roles Summary

| Role | Agent | Responsibility |
|------|-------|---------------|
| **Team Lead** | claude-opus-4-6-thinking (agy) | Planning, coordination, DevOps, sign-off |
| **Executor** | gemini-3.8-flash-high (agy) | كتابة الكود، تنفيذ المهام |
| **Reviewer** | claude-sonnet-4-6 (agy) | Code review، UAT، جودة الكود |
| **Owner** | (Product Owner) | Go/No-Go على Milestones |

---

*Generated by Team Lead — claude-opus-4-6-thinking (agy) — Codester-inc*