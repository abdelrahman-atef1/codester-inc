# Codester-inc — Full Org Chart & Operations Protocol

## Company
**Codester-inc** — Software solutions company. Free for those in need.
Name is a fun play on Monsters, Inc. 🦾

## Mission
توفير حلول برمجية مجانية تماماً للفئات المحتاجة:
- المرضى الفقراء
- أصحاب الشركات الناشئة
- أي حد محتاج tool يبدأ بيه أو يستفيد بس مش معاه يدفع

## Revenue
مش هدف أساسي دلوقتي. هندور عليه قدام.

## Cost Principles
1. التكلفة المستمرة **ثابتة وقليلة** — مش متناسبة طردياً مع عدد المستخدمين
2. Free tier أولاً في كل حاجة
3. User-owned storage — ندمج مع storage بتاع الـ user (Google Drive, etc.)
4. Flat architecture — evitar per-user pricing
5. Offline-first قد الإمكان
6. Self-hosted alternatives لما free tier يقف
7. Open-source في كل حاجة قد الإمكان

## Technical Priorities
- Flutter first لو ينفع بدون تعقيدات
- Web fallback (PWA) لو mobile مش ضروري
- CLI-built — التطوير كله via CLIs (agy/claude)

## Target Audience
- Primary: مصر
- Secondary: عالمي

---

## Org Chart

```
Owner (Abdelrahman)
  └── المدير العام (Home Brain — glm-5.2)
        │
        ├── تيم Product
        │     └── Product Manager (agy claude-sonnet-4-6)
        │
        ├── تيم Strategy
        │     └── Business Analyst (agy claude-sonnet-4-6)
        │
        ├── تيم Engineering
        │     ├── Chief Architect (agy claude-opus-4-6-thinking)
        │     ├── Team Lead (agy claude-opus-4-6-thinking)
        │     ├── Reviewer (agy claude-sonnet-4-6)
        │     ├── Executor (agy gemini-3.8-flash-high)
        │     ├── DevOps Engineer (agy gemini-3.1-pro-high)
        │     ├── Security Engineer (agy claude-sonnet-4-6)
        │     └── QA Tester (agy gemini-3.8-flash-high)
        │
        ├── تيم Design
        │     └── UI/UX Designer (agy gemini-3.1-pro-high)
        │
        ├── تيم Finance
        │     └── Accountant/CFO (agy gemini-3.1-pro-high)
        │
        ├── تيم Marketing
        │     └── Marketer/CMO (agy gemini-3.1-pro-high)
        │
        ├── تيم Legal
        │     └── Legal Consultant (agy claude-sonnet-4-6)
        │
        ├── تيم Support
        │     └── Community Manager (agy gemini-3.8-flash-high)
        │
        └── تيم R&D
              └── Researcher (agy gemini-3.1-pro-high)
```

---

## Roles & Responsibilities

### Management
| Role | Model | Responsibility |
|------|-------|---------------|
| المدير العام | ollama-cloud/glm-5.2 | يستلم requirements، بـ delegate، بـ track، بـ report للـ Owner |

### Product
| Role | CLI | Model | Responsibility |
|------|-----|-------|---------------|
| Product Manager | agy | claude-sonnet-4-6 | user stories، roadmap، priorities، يحول الفكرة لـ requirements واضحة |

### Strategy
| Role | CLI | Model | Responsibility |
|------|-----|-------|---------------|
| Business Analyst | agy | claude-sonnet-4-6 | دراسة جدوى + دراسة سوق + توصية go/no-go |

### Engineering
| Role | CLI | Model | Responsibility |
|------|-----|-------|---------------|
| Chief Architect | agy | claude-opus-4-6-thinking | system design، stack selection، architecture document، patterns |
| Team Lead | agy | claude-opus-4-6-thinking | execution plan، task distribution، progress tracking |
| Reviewer | agy | claude-sonnet-4-6 | code review، plan review، quality gate |
| Executor | agy | gemini-3.8-flash-high | write code، implement plan |
| DevOps Engineer | agy | gemini-3.1-pro-high | CI/CD، deployment، hosting، monitoring |
| Security Engineer | agy | claude-sonnet-4-6 | security audit، penetration testing، compliance |
| QA Tester | agy | gemini-3.8-flash-high | tests، quality assurance |

### Design
| Role | CLI | Model | Responsibility |
|------|-----|-------|---------------|
| UI/UX Designer | agy | gemini-3.1-pro-high | wireframes، user flow، accessibility، prototypes |

### Finance
| Role | CLI | Model | Responsibility |
|------|-----|-------|---------------|
| Accountant/CFO | agy | gemini-3.1-pro-high | cost analysis، budget، monthly tracking، flat-cost verification |

### Marketing
| Role | CLI | Model | Responsibility |
|------|-----|-------|---------------|
| Marketer/CMO | agy | gemini-3.1-pro-high | market research، content strategy، social media، outreach |

### Legal
| Role | CLI | Model | Responsibility |
|------|-----|-------|---------------|
| Legal Consultant | agy | claude-sonnet-4-6 | privacy policies، ToS، compliance (مصر + global) |

### Support
| Role | CLI | Model | Responsibility |
|------|-----|-------|---------------|
| Community Manager | agy | gemini-3.8-flash-high | community building، feedback collection، outreach للمنظمات |

### R&D
| Role | CLI | Model | Responsibility |
|------|-----|-------|---------------|
| Researcher | agy | gemini-3.1-pro-high | free tiers discovery، alternatives evaluation، cost reduction |

---

## Tools & Resources Protocol

**القاعدة:** الأدوات مش نهائية. كل موظف بيحدد متطلباته حسب التاسك، وبيبلغ المدير العام، والمدير العام بيبلغ الـ Owner.

### Current Tool Inventory
(يتحدث مع كل مشروع — مش ثابت)

### Tool Request Protocol
كل موظف لما يحتاج أداة جديدة:
1. بيـ requestها من المدير العام في الـ JSON report
2. المدير العام بيـ evaluate: هل هي مجانية؟ هل فيها تكلفة مستمرة؟
3. لو مجانية → المدير العام بيـ approve ويوفرها
4. لو فيها تكلفة → المدير العام بيبلغ الـ Owner بالـ options

### Expected Tools per Role (initial — not final)

| Role | Likely tools |
|------|-------------|
| Product Manager | MCP: Notion/GitHub Projects, web search |
| Business Analyst | web search, MCP: financial data |
| Chief Architect | MCP: GitHub, diagram tools, docs |
| Team Lead | MCP: GitHub (issues, PRs) |
| Reviewer | MCP: GitHub (PR review), linters |
| Executor | MCP: GitHub, Flutter SDK, Firebase CLI |
| DevOps | MCP: cloud providers, Docker, CI/CD |
| Security | MCP: security scanners, OWASP tools |
| QA | Flutter test tools, MCP: test reporting |
| UI/UX | MCP: Figma, web search (inspiration) |
| Accountant | MCP: financial APIs, spreadsheets, web search |
| Marketer | MCP: social media APIs, web search, analytics |
| Legal | web search (legal research), MCP: legal databases |
| Community Manager | MCP: social media, chat platforms |
| Researcher | web search, MCP: docs, GitHub (open source) |

---

## Options Protocol

كل موظف لما يرجع بالنتيجة، بيقدم options لو فيه أكتر من طريق:

```
┌─ Option A: جودة عالية، تكلفة أعلى
│  التفاصيل...
│  التكلفة: $X/شهر (ثابتة/متغيرة)
│
├─ Option B: جودة متوسطة، تكلفة أقل
│  التفاصيل...
│  التكلفة: $Y/شهر
│
└─ Option C: الحد الأدنى، تكلفة صفر
   التفاصيل...
   التكلفة: $0
```

- لو الموضوع فيه قرار إداري → المدير العام يمرره للـ Owner
- لو الموضوع تقني بحت → المدير العام يخلي الـ Chief Architect يقرر
- لو الموضوع مالي → الـ Accountant يقرر
- لو الموضوع قانوني → الـ Legal Consultant يقرر

---

## Reporting Protocol

### قاعدة الـ Signature (إجباري)
كل رد من أي موظف يبدأ بـ signature بتاعته:
```
[Emoji] [الوظيفة] — [الموديل] ([البروفايدر]):
```
أمثلة:
- `📌 المدير العام — glm-5.2 (ollama-cloud):`
- `🔍 Researcher — gemini-3.1-pro-high (agy):`
- `🏗️ Chief Architect — claude-opus-4-6-thinking (agy):`
- `⚡ Executor — gemini-3.8-flash-high (agy):`

ده إجباري في كل رد — تقارير، ميمشن، أي حاجة.

### من الموظفين للمدير العام (CLI JSON output)
```json
{
  "employee": "role_name",
  "task": "وصف المهمة",
  "status": "in_progress|done|blocked",
  "output": "النتيجة",
  "tools_needed": ["tool1", "tool2"],
  "options": [],
  "blocker": "null أو وصف المشكلة"
}
```

### من المدير العام للـ Owner

**في الـ DM (هنا):** التقارير المهمة، القرارات، الأشياء اللي محتاجة رأيك.

**في جروب Codester-inc (سيتم إنشاؤه):** تحديثات سطر واحد:
```
📊 [الموظف — الموديل] | [المهمة] → [الحالة] | [ملخص سطر واحد]
```

أمثلة:
```
📊 Team Lead — claude-opus | تخطيط تطبيق X → في التقدم | بيكتب الـ execution plan
📊 Executor — gemini-flash | تنفيذ login screen → خلصت | 3 files، 0 errors
📊 QA — gemini-flash | اختبار تطبيق X → متوقف | build فشل على Android 12
📊 Accountant — gemini-pro | تحليل تكلفة X → خلصت | $0/شهر ثابتة ✅
```

**قاعدة إجبارية:** اسم الموديل يظهر جنب اسم الموظف في كل تقرير أو mention.

---

## Project Workflow

**الـ DM = إنت تطلب وأنا orchestrate. الـ topics =双向 channels (reports + تواصل مباشر مع الموظفين).**

```
1. Owner → المدير (DM): "فكرة X"
2. المدير → Product Manager (agy): "حول الفكرة لـ requirements"
3. المدير → Marketer (agy): "درس السوق"
4. المدير → Chief Architect (agy): "صمم الـ architecture"
5. المدير → Team Lead (agy): "اكتب execution plan"
6. المدير → Accountant (agy): "حلل التكلفة"
7. المدير → Legal (agy): "راجع الـ compliance"
8. المدير → Business Analyst (agy): "اعمل دراسة جدوى"
9. Business Analyst → المدير: go / no-go
10. لو go:
    → المدير ببعث الخطة في topic 34 (Engineering) عبر conversations_send
    → الـ Engineering team بيبعت أسئلة في topic 34
    → Owner بيرد عليهم في topic 34 مباشرة
    → progress updates في topic 34
    → النتيجة النهائية في topic 34
11. المدير → Owner (DM): تقرير كامل بالخلاصة
```

**قواعد الـ topics:**
- topic 1 (General): announcements + reports عامة
- topic 34-42: output channels للـ reports +双向 communication مع الموظفين
- الـ reporting 3 خطوات: الخطة → progress → النتيجة النهائية (كلهم في نفس الـ topic)
- الموظفين يقدروا يسألوا الـ Owner أسئلة في الـ topic بتاعهم
- الـ Owner يرد عليهم مباشرة في الـ topic

---

## Fallback Chain

لو agy وقف:
1. claude --model claude-sonnet-5 (fallback لكل الأدوار)
2. claude --model claude-opus-5 (للتخطيط التقيل بس)

لو claude وقف برضه:
3. OpenClaw subagents (آخر حل — بيستهلك quota)
---

## Quality Gate Protocol (إجباري)

كل feature لازم يمر بـ 5 gates قبل الـ build:

```
Gate 1: Executor يكتب الكود
  → يجب أن يكتمل بنجاح (لو فشل → retry بـ timeout أعلى)
  → Output: كود + flutter analyze = 0 issues

Gate 2: Reviewer يراجع
  → مراجعة logic (مش بس static analysis)
  → مراجعة UX flow (هل الـ flow منطقي؟)
  → مراجعة design consistency (Paper Ledger متطبق؟)
  → مراجعة security (PIN hashing, data validation)
  → Output: approved أو changes needed

Gate 3: QA Tester يـ test
  → flutter test (unit + integration)
  → smoke test للـ features الجديدة
  → مراجعة الـ screens كلها بتفتح بدون crashes
  → Output: passed أو bugs found

Gate 4: Owner Checkpoint
  → المدير العام بيـ report للـ Owner بالنتيجة
  → الـ Owner يراجع (على فونه أو من خلال التقرير)
  → Output: approved أو changes needed

Gate 5: Build + Distribution
  → Build Agent يعمل build
  → رفع على Firebase App Distribution
  → Output: APK + link للتحميل
```

**ممنوع:** build بدون ما الـ 4 gates الأولين يـ pass.

---

## Executor Retry Protocol

لو Executor فشل (idle timeout):
1. المحاولة الأولى: timeout عادي (300s)
2. المحاولة الثانية: timeout أعلى (600s) + task أصغر
3. المحاولة الثالثة: تقسيم الـ task لـ subtasks أصغر + Executor تاني
4. لو فشل تاني: المدير العام يبلغ الـ Owner بالـ blocker

**Verification بعد كل Executor:**
- flutter analyze = 0 issues
- الـ files المطلوبة موجودة ومش فاضية
- الـ logic سليم (Reviewer يراجع)

---

## دور المدير العام (واضح ومحدد)

**المدير العام بيعمل:**
- يستلم requirements من الـ Owner
- يـ delegate للموظفين المناسبين
- يـ track progress
- يـ report للـ Owner
- يـ ensure Quality Gates بتـ pass
- يـ coordinate بين الـ teams

**المدير العام مبيعملش:**
- search عن حلول تقنية (ده شغل Researcher / Business Analyst)
- write code (ده شغل Executor)
- review code (ده شغل Reviewer)
- test (ده شغل QA)
- design (ده شغل UI/UX Designer)
- build (ده شغل Build Agent / DevOps)

**لو محتاج بحث تقني:** delegate للـ Researcher أو Business Analyst
**لو محتاج قرار تقني:** delegate للـ Chief Architect
**لو محتاج قرار مالي:** delegate للـ Accountant

---

## Execution Method (إجباري — محدّث 2026-09-05)

### المشكلة اللي اكتشفناها
`sessions_spawn` بيستخدم ollama-cloud/glm-5.2 (default model) لكل الموظفين.
يعني كل الموظفين (Executor, Reviewer, Architect, etc.) شغالين بـ glm-5.2،
مش بـ gemini ولا claude. ده سبب:
- idle timeout (glm-5.2 ببطأ على الـ tasks الكبيرة)
- استهلاك كوتا ollama-cloud بسرعة
- جودة كود أقل

### الحل
الموظفين يشتغلوا عبر **agy CLI مباشرة** باستخدام `exec`، مش `sessions_spawn`.

| الموظف | الـ command |
|--------|-------------|
| Executor | `exec: agy -p "prompt" --model gemini-3.8-flash-high` |
| Reviewer | `exec: agy -p "prompt" --model claude-sonnet-4-6` |
| Chief Architect | `exec: agy -p "prompt" --model claude-opus-4-6-thinking` |
| Researcher | `exec: agy -p "prompt" --model gemini-3.1-pro-high` |
| QA Tester | `exec: agy -p "prompt" --model gemini-3.8-flash-high` |

### القواعد
- `sessions_spawn` = للـ tasks البسيطة اللي تنفع مع glm-5.2 (research, reports, etc.)
- `exec` + agy = للـ coding work (Executor, Reviewer, Architect)
- الـ USER.md بتقول: "use Claude CLI for planning, OpenCode/Antigravity for execution"
- الـ coding كله عبر agy CLI بـ models الصح

---

## CLI Policy (مححدّث 2026-09-05)

**Claude CLI هو الأساسي لكل التنفيذ والـ research والـ implementations.**

- كل الموظفين → `claude -p "prompt" --dangerously-skip-permissions`
- ممنوع استخدام `sessions_spawn` للـ coding work (بيستخدم glm-5.2)
- ممنوع استخدام `agy` إلا كـ fallback أخير
- ممنوع استخدام `sessions_spawn` للـ research (بيستخدم glm-5.2)
- Claude CLI اتاختبر بنجاح ✅

| الموظف | الـ command |
|--------|-------------|
| Executor | `exec: claude -p "prompt" --dangerously-skip-permissions` |
| Reviewer | `exec: claude -p "prompt" --dangerously-skip-permissions` |
| Architect | `exec: claude -p "prompt" --dangerously-skip-permissions` |
| Researcher | `exec: claude -p "prompt" --dangerously-skip-permissions` |
| QA Tester | `exec: claude -p "prompt" --dangerously-skip-permissions` |
