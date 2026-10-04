# Codester-inc — Current State

> هذا الملف يُقرأ تلقائياً في كل topic. يتم تحديثه عند تغير المهام.
> آخر تحديث: 2026-09-05 20:40 EDT

## الشركة
Codester-inc — شركة حلول برمجية مجانية للفئات المحتاجة.

## المشاريع النشطة

### 📋 مشروع 1: فاتورة (Fatura)
**النوع:** POS + فواتير + مخزون للبيزنس الميكرو
**Design:** Paper Ledger (cream paper + ink black + stamp red + forest green)
**Stack:** Flutter + Drift + Riverpod + Material 3
**Firebase:** codester-inc (App Distribution شغال)

**الحالة: MVP + Sync Module قيد التطوير**

#### المكتمل:
- ✅ Phase 1: Foundation + Inventory + Paper Ledger Design (48 ملف)
- ✅ Phase 2: POS + Invoice + Report (18 ملف)
- ✅ Phase 3: Auth + Users + Settings + Providers (11 ملف)
- ✅ Feedback Module (بلاغات + طلبات features)
- ✅ Fixes: Onboarding persistence + Role selector + Nav tabs + Invoice FAB
- ✅ Tests: 13 ملف (integration + unit) — All passed
- ✅ Build #5 على Firebase (30.4 MB arm64 release)

#### قيد التطوير:
- 🔄 Sync Module (FCM + Local HTTP + QR) — 11 ملف اتكتبت، فيها 39 issues محتاجة إصلاح
- ⚠️ مشكلة: agy عبر exec بيتايم اوت على الـ tasks الكبيرة

#### المؤجل:
- مشاركة فاتورة (واتساب/SMS)
- طباعة Bluetooth
- تنبيهات النفاد
- تقرير شهري
- Google Drive backup

---

### 📋 مشروع 2: مهامي (Abduu Tasks) — v3.2.0
**النوع:** تطبيق تذكيرات يومية بـ Glassmorphism + 3 themes
**Stack:** Flutter
**Firebase:** codester-inc

**الحالة: v3.2.0+13 على Firebase App Distribution**

#### المكتمل:
- ✅ user stories v2 (17 stories)
- ✅ architecture v2 (16 ملف)
- ✅ redesign كامل (glassmorphism + 3 themes)
- ✅ تمرين الجيم 🚴
- ✅ descriptions لكل تاسك
- ✅ تعديل وحذف كل المهام (long press)
- ✅ time override للـ defaults
- ✅ Zen Focus theme بـ Readex Pro font
- ✅ v3.2.0+13 على Firebase

#### المهام القادمة:
- ميزة التخطيط الأسبوعي
- Local notifications بدل Firebase FCM
- ربط التطبيق بالـ dispatcher (sync)
- تحسين الـ UI أكثر

---

## الـ CLI الأساسي للتنفيذ
- **Claude CLI** هو الأساسي للتنفيذ والـ research وكل الـ implementations
- كل الموظفين → `claude -p "..." --dangerously-skip-permissions`
- ممنوع استخدام sessions_spawn للـ coding work
- ممنوع استخدام agy إلا كـ fallback أخير
- Claude CLI اتاختبر بنجاح ✅

## مشاكل معروفة
- `sessions_spawn` بيستخدم glm-5.2 لكل الموظفين (مش gemini/claude) — تم اكتشافه وتوثيقه
- agy عبر exec بيتايم اوت على الـ tasks الكبيرة — محتاج تقسيم لـ micro-tasks
- الـ topics مش بتعرف التعديلات اللي تحصل في الـ DM تلقائياً
- serveo/ngrok مش مستقر للـ preview

## القرارات المعتمدة
- اللوجو: Concept 3 (Cyber Serpent)
- التسجيل: Option C (تأجيل)
- فاتورة UI: Material 3 + Paper Ledger
- فاتورة Animations: 120fps flagship / 60fps budget
- فاتورة Sync: FCM + Local HTTP + QR = $0
- مهامي UI: Glassmorphism + 3 themes (Playful, Zen Focus, Bold Executor)
- مهامي Font: Readex Pro للـ Zen Focus

## الأدوات المتاحة
- CLIs: claude (أساسي), agy (fallback), opencode, cursor-agent
- MCP: fetch, firebase, git
- Java 17: /home/kali/jdk17
- Flutter 3.47.2: ~/flutter/bin/flutter
- Android SDK: /home/kali/android-sdk
- Firebase CLI: v15.29.0
- Firebase Project: codester-inc
- Test Group: codester-testers
- Testers: abduu00001111@gmail.com, abdelrahman.atef.147@gmail.com
- ngrok: joseph-nonhydrated-cecille.ngrok-free.app