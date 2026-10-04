# 🎬 فاتورة — Animation Spec

**Designer:** gemini-3.1-pro-high (agy) — Codester-inc
**Theme:** Material 3 + Codester dark (#0a0e1a, #00d9ff, #6c5ce7)
**Last Updated:** 2026-09-04

---

## Animation Principles

1. **Consistent Duration Scale** — كل الأنيميشن تتبع نظام موحّد:
   - `micro` = 150ms (ripple, tap)
   - `short` = 250ms (button press, toggle)
   - `medium` = 350ms (page transition, card slide)
   - `long` = 500ms (success celebration, count-up)
   - `extra` = 800ms+ (onboarding progress, confetti)

2. **Meaningful Motion** — كل حركة بتح传达 معنى: direction = spatial relationship, scale = importance, color shift = state change. مفيش animation للزينة بس.

3. **No Unnecessary Animation** — البيزنس المستهدف (كشك/متجر صغير) محتاج سرعة. الـ animations المزهّبية (confetti، particle effects) بتظهر بس في لحظات الـ success الحقيقية (إتمام بيع). باقي التطبيق سريع وسلس.

4. **Respect Reduced Motion** — `MediaQuery.disableAnimations` → يلغي كل الـ non-essential animations ويستبدلها بـ instant state changes.

5. **RTL-Aware** — كل الـ slide directions بت反转 للـ RTL: `slideInFromLeft` → `slideInFromRight` تلقائياً عبر `Directionality` widget.

---

## Performance Rules

| Rule | Detail |
|------|--------|
| **120fps target** | 120fps على flagship devices (ProMotion/high-refresh) — 60fps minimum على budget devices |
| **GPU-accelerated only** | تستخدم transform + opacity بس (what Flutter optimizes natively)؛ تجنب animate width/height/margin |
| **RepaintBoundary** | كل card/list item فيه animation يتحط جوه `RepaintBoundary` لعزل الـ repaint |
| **No heavy animations on budget phones** | Confetti + Lottie = optional، بتتعطل لو `DeviceInfo.performanceTier == 'low'` |
| **Implicit > Explicit** | 90% من الأنيميشن implicit (AnimatedContainer, AnimatedSwitcher) — أسرع وأبسط |
| **Max 3 concurrent** | مفيش أكتر من 3 animations متزامنة على نفس الـ screen |
| **Avoid jank** | `ListView.builder` + `itemExtent` للـ lists المعروفة الـ height |
| **Shader warmup** | الـ POS screen و barcode overlay بيتعملهم `ShaderWarmUp` في `main()` لتفادي first-frame jank |

---

## 1. Page Transitions

| From → To | Type | Flutter Method | Duration | Curve | Performance |
|-----------|------|----------------|----------|-------|-------------|
| Onboarding step → step | Explicit | `PageView` + custom `PageTransitionsBuilder` (horizontal slide) | 350ms | `Curves.easeInOutCubicEmphasized` | Low |
| Onboarding → Home | Explicit | `FadeTransition` + scale (0.95→1.0) | 400ms | `Curves.easeOut` | Low |
| Bottom Nav tab → tab | Implicit | `AnimatedSwitcher` (fade + slide 12px Y) | 250ms | `Curves.easeInOut` | Low |
| POS entry (from nav) | Explicit | `ScaleTransition` (0.85→1.0) + `FadeTransition` (POS button expands full screen — Hero-like) | 400ms | `Curves.easeOutBack` (slight overshoot) | Medium |
| POS exit → back to nav | Explicit | Reverse of entry: scale(1.0→0.85) + fade, shrinking back to button position | 300ms | `Curves.easeIn` | Medium |
| List item → Detail (Invoice) | Explicit | `Hero` animation (invoice card → detail header) | 400ms | `Curves.easeInOut` | Low |
| Settings → Sub-page | Explicit | `PageRouteBuilder` slide from right (RTL: from left) + fade | 300ms | `Curves.easeInOut` | Low |
| Dialog/Modal open | Implicit | `showModalBottomSheet` (default slide-up) or `showDialog` with scale-in | 250ms | `Curves.easeOut` (sheet) / `Curves.easeOutBack` (dialog) | Low |

**Implementation Notes:**
- Custom `pageTransitionsTheme` في `ThemeData` لتوحيد كل الـ push transitions
- POS entry/exit: يستخدم `Hero` widget بين POS button و full screen POS — يعطي إحساس "الزر بيكبر ويملأ الشاشة"

---

## 2. Micro-interactions (Button & Touch Feedback)

| Element | Type | Flutter Method | Duration | Curve | Haptic | Performance |
|---------|------|----------------|----------|-------|--------|-------------|
| All buttons (tap) | Implicit | `InkWell` (Material ripple — default) | 150ms (ripple) | Linear (ripple) | `HapticFeedback.lightImpact()` | Low |
| POS checkout button | Explicit | `ScaleTransition` (1.0→0.96 on down, 0.96→1.0 on up) + glow `AnimatedContainer` (shadowColor opacity) | 200ms | `Curves.easeOut` | `HapticFeedback.mediumImpact()` | Medium |
| Payment method chips | Implicit | `AnimatedContainer` (selected: bg color + border + scale 1.05) | 200ms | `Curves.easeInOut` | `HapticFeedback.selectionClick()` | Low |
| Search bar (focus) | Implicit | `AnimatedContainer` (border color cyan → purple, width expand) | 200ms | `Curves.easeInOut` | None | Low |
| Toggle (tax on/off) | Implicit | `AnimatedSwitcher` + `AnimatedContainer` (thumb position via `AnimatedAlign`) | 250ms | `Curves.easeInOutBack` | `HapticFeedback.lightImpact()` | Low |
| PIN digit entry | Explicit | Scale pop (0.8→1.0) on each dot fill + color change cyan | 150ms | `Curves.easeOutBack` | `HapticFeedback.lightImpact()` per digit | Low |
| PIN error shake | Explicit | `Transform.translate` keyframe shake (±8px, 3 oscillations) | 400ms | `Curves.elasticOut` | `HapticFeedback.heavyImpact()` | Low |
| FAB / Add product | Implicit | `AnimatedScale` (1.0→0.9 on press) | 150ms | `Curves.easeOut` | `HapticFeedback.lightImpact()` | Low |
| Bottom nav icon | Implicit | `AnimatedContainer` (icon scale 1.0→1.2 on selected, color tween gray→cyan) | 200ms | `Curves.easeOutBack` | `HapticFeedback.selectionClick()` | Low |
| Delete swipe (cart item) | Explicit | `Dismissible` (drag + slide-out) | 300ms (auto) | `Curves.easeOut` | `HapticFeedback.mediumImpact()` on dismiss | Low |
| Quantity stepper (+/-) | Implicit | `AnimatedSwitcher` (number flip) + `AnimatedScale` on button | 200ms | `Curves.easeInOut` | `HapticFeedback.lightImpact()` | Low |

---

## 3. State Transitions (Empty → Loading → Loaded → Error)

| State Change | Type | Flutter Method | Duration | Curve | Performance |
|--------------|------|----------------|----------|-------|-------------|
| Empty → Loading | Implicit | `AnimatedSwitcher` (empty illustration → shimmer skeleton) | 250ms | `Curves.easeInOut` | Low |
| Loading → Loaded | Implicit | `AnimatedSwitcher` (shimmer → content) + `FadeTransition` (opacity 0→1) | 300ms | `Curves.easeOut` | Low |
| Loaded → Error | Implicit | `AnimatedSwitcher` (content → error widget) + subtle scale-down (1.0→0.98→1.0) | 250ms | `Curves.easeInOut` | Low |
| Error → Retry → Loading | Implicit | `AnimatedRotation` on retry icon (spin) + `AnimatedSwitcher` | 250ms | `Curves.easeInOut` (fade) + `Curves.linear` (spin) | Low |
| Empty state illustration | Explicit | `Lottie` (gentle float animation — 2 frames/sec, very subtle) | Loop, 3000ms | `Curves.easeInOut` | Low (small Lottie) |
| Offline banner appearance | Implicit | `AnimatedSlide` (slide down from top -40px → 0) + `AnimatedOpacity` | 300ms | `Curves.easeOut` | Low |

**Pattern:**
```dart
// Unified state transition wrapper
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  switchInCurve: Curves.easeOut,
  switchOutCurve: Curves.easeIn,
  child: _buildStateWidget(state), // returns appropriate widget per state
)
```

---

## 4. POS-Specific Animations

### 4a. إضافة منتج للسلة (Add to Cart)

| Step | Type | Method | Duration | Curve | Performance |
|------|------|--------|----------|-------|-------------|
| Product card tap → cart item appears | Explicit | `Hero` (product icon → cart row thumbnail) OR `AnimatedPositioned` (fly-to-cart) | 400ms | `Curves.easeInOut` | Medium |
| Cart item slide-in | Explicit | `SlideTransition` (from right +12px → 0) + `FadeTransition` (0→1) | 300ms | `Curves.easeOutBack` (slight bounce) | Low |
| Cart list expansion | Implicit | `AnimatedContainer` (cart section height grows) | 250ms | `Curves.easeInOut` | Low |
| Cart badge count bump | Explicit | `AnimatedScale` (1.0 → 1.3 → 1.0) on badge number | 300ms | `Curves.elasticOut` | Low |
| Total number update | Explicit | Count-up animation (see §7) | 400ms | `Curves.easeOut` | Low |

**Implementation:** الـ "fly-to-cart" effect اختياري — لو الـ device performance low، بيتعمل slide-in بس بدون hero.

### 4b. إتمام البيع (Checkout Success)

| Step | Type | Method | Duration | Curve | Performance |
|------|------|--------|----------|-------|-------------|
| Checkout button press feedback | Explicit | Scale(0.96→1.0) + glow pulse (shadow opacity 0.4→0.8→0) | 200ms | `Curves.easeOut` | Medium |
| Success overlay fade-in | Explicit | `FadeTransition` (dimmed bg overlay opacity 0→0.6) | 200ms | `Curves.easeIn` | Low |
| Checkmark draw | Explicit | `CustomPaint` + `AnimationController` (path metric → progressive stroke draw) | 500ms | `Curves.easeOut` | Low |
| Checkmark color fill | Explicit | `AnimatedContainer` (stroke cyan→success green #00e676) | 300ms (after draw completes) | `Curves.easeInOut` | Low |
| "تم البيع" text | Explicit | `SlideTransition` (slide up 20px + fade in) | 300ms | `Curves.easeOutBack` | Low |
| Confetti burst | Explicit | `confetti` package (or custom `CustomPainter` — 20 particles, gravity + fade) | 1200ms | `Curves.easeOut` (gravity) | **High** — gated behind `performanceTier != 'low'` |
| Action buttons (print/share/new sale) | Explicit | Staggered `FadeTransition` + `SlideTransition` (50ms apart) | 300ms each, 50ms stagger | `Curves.easeOut` | Low |
| Overlay dismiss | Explicit | `FadeTransition` (1→0) + `ScaleTransition` (1.0→0.9) | 250ms | `Curves.easeIn` | Low |

**Implementation:**
```dart
// Checkmark draw via path animation
class CheckmarkPainter extends CustomPainter with AnimationController {
  // Uses PathMetric to progressively draw the ✓ stroke
  // animation drives progress from 0.0 → 1.0
}
```

### 4c. حذف منتج من السلة (Remove from Cart)

| Step | Type | Method | Duration | Curve | Performance |
|------|------|--------|----------|-------|-------------|
| Swipe-to-delete | Explicit | `Dismissible` (drag right → slide-out) | 300ms (auto after threshold) | `Curves.easeOut` | Low |
| Manual delete (trash icon) | Explicit | `AnimatedSize` (item collapses to 0 height) + `FadeTransition` (1→0) | 250ms | `Curves.easeInOut` | Low |
| Total number update | Explicit | Count-down animation (reverse of count-up) | 400ms | `Curves.easeIn` | Low |
| Cart badge count | Explicit | `AnimatedScale` (1.0 → 0.7 → 1.0) on badge | 250ms | `Curves.elasticOut` | Low |
| Cart empty state | Implicit | `AnimatedSwitcher` (cart list → "السلة فارغة" illustration) | 300ms | `Curves.easeInOut` | Low |

---

## 5. List Animations (Staggered)

| Element | Type | Method | Duration | Curve | Stagger | Performance |
|---------|------|--------|----------|-------|---------|-------------|
| Invoice list items | Explicit | `AnimatedList` + custom `ItemBuilder` (slide + fade per item) | 300ms per item | `Curves.easeOut` | 50ms between items, max 8 staggered | Low |
| Product grid (POS) | Explicit | `GridView.builder` + `AnimatedBuilder` (scale 0.9→1.0 + fade, staggered) | 250ms per item | `Curves.easeOutBack` | 40ms between items | Medium (if >20 items) |
| Dashboard cards | Explicit | `AnimatedSwitcher` + staggered `FadeTransition` (each card 80ms apart) | 300ms | `Curves.easeOut` | 80ms | Low |
| Search results | Explicit | `AnimatedList` (slide-in from right, fade) | 250ms | `Curves.easeOut` | 30ms | Low |
| Notification/transaction history | Explicit | `AnimatedList` with `SliverAnimatedList` for scroll perf | 250ms | `Curves.easeOut` | 50ms | Low |

**Implementation Pattern:**
```dart
// Staggered list animation
class StaggeredListItem extends StatefulWidget {
  final int index; // drives stagger delay
  // ...
  // AnimationController(duration: 300ms)
  // interval: index * 50ms
}
```

**Performance Note:** Staggering stops after 8 items — باقي العناصر تظهر فوراً لتفادي animation fatigue.

---

## 6. Bottom Navigation

| Element | Type | Method | Duration | Curve | Performance |
|---------|------|--------|----------|-------|-------------|
| Tab switch (content) | Implicit | `AnimatedSwitcher` (cross-fade + slide 12px Y) | 250ms | `Curves.easeInOut` | Low |
| Selected icon scale | Implicit | `AnimatedScale` (1.0→1.15) + color tween (gray→cyan) | 200ms | `Curves.easeOutBack` | Low |
| Unselected icon | Implicit | `AnimatedScale` (1.15→1.0) + color tween (cyan→gray) | 200ms | `Curves.easeIn` | Low |
| POS button (center) — glow pulse | Explicit | `AnimatedContainer` (boxShadow: cyan glow 8px→16px→8px, loop) | 2000ms (loop) | `Curves.easeInOut` | **Medium** — only when POS is NOT active tab |
| POS button — tap | Explicit | `AnimatedScale` (1.0→0.9→1.0) + glow burst (shadow opacity 0.6→1.0→0.6) | 300ms | `Curves.elasticOut` | Medium |
| Badge on nav icon | Implicit | `AnimatedSwitcher` (number changes with scale pop) | 200ms | `Curves.easeOutBack` | Low |

**Glow Implementation:**
```dart
// POS button glow — pulsing boxShadow
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Color(0xFF00d9ff),
        blurRadius: _glowAnimation.value, // 8→16→8 loop
        spreadRadius: 2,
      ),
    ],
  ),
)
```

**Performance:** الـ glow pulse بيتوقف لو الـ POS tab نشط — مفيش لزوم للـ pulse وأنت جوّه الـ POS screen.

---

## 7. Number Animations (Count-Up)

| Element | Type | Method | Duration | Curve | Performance |
|---------|------|--------|----------|-------|-------------|
| POS total (cart total) | Explicit | `TweenAnimationBuilder<int>` (0→target value, formatted as currency) | 400ms | `Curves.easeOut` | Low |
| Cart total on item add | Explicit | `TweenAnimationBuilder` (previous→new value) | 400ms | `Curves.easeOut` | Low |
| Cart total on item remove | Explicit | `TweenAnimationBuilder` (previous→new value, reverse) | 400ms | `Curves.easeIn` | Low |
| Dashboard revenue number | Explicit | `TweenAnimationBuilder<double>` (0→total) — first load only | 600ms | `Curves.easeOut` | Low |
| Quantity stepper | Explicit | `AnimatedSwitcher` (number flip: old→up, new→from down) | 200ms | `Curves.easeInOut` | Low |
| Tax amount | Explicit | `TweenAnimationBuilder<double>` (0→tax value) | 400ms | `Curves.easeOut` | Low |
| Change due (الباقي) | Explicit | `TweenAnimationBuilder<double>` (0→change) — triggers on payment amount change | 300ms | `Curves.easeOut` | Low |

**Implementation:**
```dart
// Count-up currency animation
TweenAnimationBuilder<double>(
  tween: Tween(begin: oldValue, end: newValue),
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeOut,
  builder: (context, value, _) => Text(
    '${value.toStringAsFixed(2)} ${currencySymbol}',
    style: totalTextStyle,
  ),
)
```

**Note:** الأرقام بتظهر فوراً لو `disableAnimations` = true. لو الفرق < 1.0 (تعديل صغير) مفيش animation — فوري.

---

## 8. Barcode Scanning

| Element | Type | Method | Duration | Curve | Performance |
|---------|------|--------|----------|-------|-------------|
| Scanner overlay fade-in | Explicit | `FadeTransition` (0→1) + camera preview init | 300ms | `Curves.easeOut` | Low |
| Scan line (horizontal sweep) | Explicit | `AnimatedBuilder` + `AnimationController` (repeat: line moves top→bottom→top) | 1500ms (loop) | `Curves.easeInOut` | Low (simple transform) |
| Corner brackets | Implicit | `AnimatedContainer` (brackets scale 0.9→1.0 on appear, stay static after) | 250ms | `Curves.easeOutBack` | Low |
| Scan success (barcode detected) | Explicit | `AnimatedContainer` (brackets color cyan→green, brief flash) | 200ms | `Curves.easeInOut` | Low |
| Success haptic | — | `HapticFeedback.heavyImpact()` | — | — | — |
| Scanner overlay dismiss | Explicit | `FadeTransition` (1→0) | 200ms | `Curves.easeIn` | Low |
| "Scanning..." text | Implicit | `AnimatedSwitcher` (pulsing dots: "●○○" → "●●○" → "●●●" → repeat) | 600ms (loop) | Linear | Low |

**Scan Line Implementation:**
```dart
// Custom scan line animation
AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500),
)..repeat(reverse: true);

// Positioned widget: top = _animation.value * scanAreaHeight
// Use Transform.translate for GPU-friendly animation
```

---

## 9. Pull-to-Refresh

| Element | Type | Method | Duration | Curve | Performance |
|---------|------|--------|----------|-------|-------------|
| Custom indicator | Explicit | `CustomPainter` + `AnimationController` tied to scroll offset | Follows drag | Linear (drag) / `Curves.easeOut` (release) | Low |
| Pull threshold (drag) | — | Indicator scales 0→1.0 as user drags (proportional to `DragOffset / threshold`) | — | Linear | Low |
| Release + refresh | Explicit | `AnimationController` (indicator spins 360°) while loading | 1000ms (loop) | `Curves.linear` (spin) | Low |
| Refresh complete | Explicit | Indicator scales 1.0→0 + fade, list bounces back | 250ms | `Curves.easeOut` | Low |
| New content slide-in | Explicit | Staggered `AnimatedList` insertion at top (see §5) | 300ms | `Curves.easeOut` | Low |

**Custom Indicator Design:**
- شكل: Codester logo مبسّط (C shape) بيدور
- Color: cyan (#00d9ff) بيتفتّح من gray→cyan مع زيادة الـ drag
- لما يوصل threshold: glow effect خفيف

**Implementation:** `RefreshIndicator` widget مع custom `indicatorBuilder` ( أو `custom_refresh_indicator` package للتحكم الكامل).

---

## 10. Loading States (Skeleton/Shimmer)

| Element | Type | Method | Duration | Curve | Performance |
|---------|------|--------|----------|-------|-------------|
| Invoice card skeleton | Explicit | `Shimmer.fromColors` (base #1e2538 → highlight #2a3349, gradient sweep) | 1500ms (loop) | `Curves.easeInOut` (sweep) | Low |
| Product grid skeleton | Explicit | `Shimmer` (6 placeholder cards, rounded rect, same radius as real cards) | 1500ms (loop) | `Curves.easeInOut` | Low |
| POS cart skeleton | Explicit | `Shimmer` (3 placeholder rows, text-width boxes) | 1500ms (loop) | `Curves.easeInOut` | Low |
| Dashboard stats skeleton | Explicit | `Shimmer` (4 stat cards, number + label placeholders) | 1500ms (loop) | `Curves.easeInOut` | Low |
| Skeleton → content transition | Implicit | `AnimatedSwitcher` (shimmer → real content, fade) | 300ms | `Curves.easeOut` | Low |

**Implementation:**
```dart
Shimmer.fromColors(
  baseColor: Color(0xFF1e2538),   // bg-elevated
  highlightColor: Color(0xFF2a3349), // lighter shade
  period: const Duration(milliseconds: 1500),
  child: _buildSkeletonCard(),
)
```

**Skeleton Design Rules:**
- نفس الـ dimensions والـ radius بتوع الـ content الحقيقي
- Base color = `bg-elevated`, highlight = +12% lightness
- المدة 1500ms — أبطأ من الـ micro-interactions عشان يبقى واضح إنه loading مش content
- مفيش shimmer لو الـ data موجود (cached) — يظهر فوراً

---

## Summary Table — Package Dependencies

| Package | Usage | Priority |
|---------|-------|----------|
| `flutter` (built-in) | 90% من الأنيميشن (AnimatedContainer, AnimatedSwitcher, TweenAnimationBuilder, Hero) | Required |
| `shimmer` | Skeleton loading | Required |
| `confetti` | Checkout success celebration | Optional (gated by performance) |
| `lottie` | Empty state illustrations | Optional |
| `custom_refresh_indicator` | Custom pull-to-refresh | Recommended |
| `haptic_feedback` (built-in) | All micro-interactions | Required |

---

## Accessibility

- `MediaQuery.disableAnimations` → كل الأنيميشن تتبدل بـ instant state changes
- `Semantics` labels على كل animated state changes (e.g. "تم تحديث الإجمالي إلى 142.50 جنيه")
- Confetti + Lottie = تتعطل تلقائياً لو `disableAnimations` = true
- لا reliance على color بس — كل state changes بيرافقها icon أو text