Design a complete, next-generation, breathtaking mobile app UI kit for "FocusFlow Mobile" — a personal medical exam study OS for USMLE Step 1 and FMGE. This is NOT a generic productivity app. It is a deeply personal, data-rich, ultra-animated study companion built for one power user named Arsh.

The design must feel like Apple's iOS 26 Liquid Glass design language crossed with Linear.app's precision and a medical-grade dashboard's data density. Every surface must feel ALIVE — breathing, glowing, morphing. This should be the most animated, most premium Flutter mobile UI ever conceived.

---

## 🎨 DESIGN SYSTEM & BRAND IDENTITY

**App Name:** FocusFlow Mobile
**Tagline:** "Your Personal Study OS"
**Personality:** Futuristic, ultra-premium, calm intelligence, warm power — like a NASA control room designed by Apple.

### Color Palette (STRICT — DO NOT DEVIATE)
- Light Background: #F8F7FF (warm white with barely-there lavender tint)
- Dark Background: #0E0E1A (deep rich charcoal — NOT navy, NOT pure black)
- Primary Accent: #6366F1 (vibrant indigo/violet)
- Secondary Accent: #818CF8 (lighter indigo for chips and tags)
- Surface Light: rgba(255,255,255,0.72) — liquid glass light
- Surface Dark: rgba(26,26,46,0.65) — liquid glass dark with indigo glow
- Liquid Glass Border Light: rgba(255,255,255,0.45)
- Liquid Glass Border Dark: rgba(99,102,241,0.3)
- Success Green: #22C55E
- Warning Amber: #F59E0B
- Danger Red: #EF4444
- Text Primary Light: #1E1E2E
- Text Primary Dark: #F4F4FF
- Text Secondary: #6B7280
- Glow Indigo: rgba(99,102,241,0.25) — used for card glow halos

### Typography
- Headings / Stats: Inter Bold (700-800), 28-40px
- Card Titles: Inter SemiBold (600), 16-20px
- Body: Inter Regular (400), 14-15px
- Labels / Chips: Inter Medium (500), 11-12px

### 🌊 iOS 26 LIQUID GLASS DESIGN LANGUAGE (APPLY EVERYWHERE)
Every card, every sheet, every nav element must use Liquid Glass:
- Backdrop blur: 24-40px (heavier blur on hero elements)
- Background fill: semi-transparent (12-20% opacity solid fill beneath the blur)
- Border: 1px, rgba(255,255,255,0.4) light / rgba(99,102,241,0.35) dark
- Inner glow: subtle white inner shadow top-left (light mode), indigo inner glow (dark mode)
- Cards appear to FLOAT above the background — they have depth
- Background behind cards: animated flowing gradient mesh (indigo + violet + deep blue particles slowly drifting)
- The background itself is ALIVE — slow aurora-like gradient animation, never static

### ✨ ANIMATION SPECIFICATIONS (CRITICAL — THIS IS THE SOUL OF THE APP)
EVERY element must have a defined animation:
- Screen entry: elements cascade in from bottom with spring physics (stagger 60ms per element)
- Cards: on load, scale from 0.92 → 1.0 with spring bounce (tension 180, friction 20)
- Numbers / stats: count-up animation on screen load (0 → actual value, 800ms ease-out)
- Progress bars: fill animation left-to-right on screen entry (600ms ease-out spring)
- Bottom nav: active tab icon morphs with liquid spring, glow dot pulses below
- FAB button: continuous slow pulsing indigo glow ring (2s loop, ease-in-out)
- Gradient backgrounds: slow aurora drift animation (8s loop, subtle hue shift)
- Liquid glass cards: on tap, ripple of light spreads across the glass surface
- Swipe gestures: spring-physics rubber band at edges
- Lottie celebrations: full-screen star-burst + confetti on goal completion
- Page transitions: shared element Hero transitions with spring curve
- Skeleton loaders: shimmer wave in lavender-indigo gradient
- Toggle switches: liquid morphing animation (pill fills and slides)
- Charts: draw-on animation — lines draw themselves from left to right
- Donut charts: arc fills with spring overshoot then settle

### Visual Language
- ALL surfaces: Liquid Glass (as defined above) — NO solid opaque cards
- Glassmorphism intensity: hero cards = heavy blur + glow, list rows = lighter blur
- Depth system: Background (Z=0) → Ambient glow layer (Z=1) → Cards (Z=2) → FAB/Nav (Z=3) → Modals (Z=4)
- Icon style: Lucide Icons, stroke 1.5px, size 20px — icons subtly glow on active state
- Spacing: 8px base grid
- Bottom nav: floating pill, liquid glass, 72px height, heavy backdrop blur
- Animated mesh gradient background on EVERY screen — slow drifting indigo/violet/deep-blue aurora

---

## 📱 SCREENS — ALL 8 in LIGHT + DARK MODE (16 artboards total)

### SCREEN 1: Dashboard (Home)
The most important screen. A living, breathing command center.

**Animated background:** Slow aurora mesh gradient drifting behind all cards.

**Hero countdown section:**
- Two floating liquid glass cards side-by-side: "FMGE · 107 days" (indigo gradient) and "USMLE Step 1 · ~102 days" (violet gradient)
- Each card has an animated circular progress ring (arc draws on load with spring overshoot)
- Cards have heavy glassmorphism, glow halos, and a subtle shimmer sweep animation on loop
- On entry: cards slide up with spring bounce

**Greeting:**
- "Good morning, Arsh 🌅" — Inter Bold 32px
- Subtitle: "Day 18 of 123. Every page matters." — secondary text, animated typewriter effect on load

**Pace Insight Card (liquid glass, full width):**
- "Your Pace" title with animated sparkline chart (line draws itself on load)
- Giant stat: "8.3 pages/day" — count-up animation from 0
- Smart label: "FA done: May 1 — ✅ On track for FMGE · ⚠️ Push harder for Step 1"
- Left edge: animated indigo-to-violet gradient bar that pulses gently

**Time Budget Card:**
- "Today's Time Budget" with animated horizontal segmented bar
- Segments animate in sequence: Sleep (charcoal) → Prayers (indigo tint) → Study (indigo gradient)
- "7h 20min FREE" stat — count-up animation, large bold

**Today's Goals:**
- 4 animated rows: FA Pages (6/10), Anki (✅ Done), Sketchy Micro (1/2), Revision (3 due)
- Each progress bar animates fill on load
- Completed rows: pulse green glow → checkmark morphs in with spring
- Tap any row: scale 0.97 with haptic, expands inline detail

**Streak strip:**
- "🔥 Day 4 streak" — fire icon with warm amber glow halo, pulsing
- Rotating motivational quote in liquid glass card (fade transition between quotes)

---

### SCREEN 2: Today's Plan
A premium time-blocked planner. Liquid glass timeline.

**Top:**
- "Friday, March 13" bold header + "Available: 7h 20min" animated badge
- Overflow warning banner (amber liquid glass pill) animates in from top if over budget

**Prayer blocks:**
- Liquid glass blocks with indigo tint, mosque icon, dashed left border
- Fajr 05:25, Dhuhr 12:38, Asr 16:08, Maghrib 18:12, Isha 19:38
- Not interactable — appear with subtle locked-icon animation

**Study blocks (each unique liquid glass accent):**
- FA Reading: violet gradient glass, "FA Pages 50–59 | Biochemistry", 07:00–09:30
- Anki: amber glass card, animated flashcard flip icon
- Sketchy: teal glass card, sketch-style icon animation
- UWorld: green glass card, target/bullseye icon

**Time calculator strip:**
- Animated running total as you add/remove blocks
- "⚠️ 40 min over budget" — pulsing amber warning

**FAB:** Large indigo button with pulsing glow ring. Tap → bottom sheet slides up with spring

---

### SCREEN 3: Tracker (4 Tabs)
Tab bar: FA 2025 | Sketchy | Pathoma | UWorld

**FA 2025 Tab:**
- Subject filter pills — tap animates active pill with liquid fill slide
- Subject progress card: animated fill bar, percentage counts up
- Page list rows: each row slides in with stagger animation
- Swipe right → green "Mark Read" reveal; swipe left → options reveal
- Long press → context menu morphs in with spring scale

**Sketchy Tab:**
- Micro / Pharma pill switcher with liquid slide animation
- Each organism/drug card: 3 status dots that tap-through with spring morph
- Mastered items: subtle green glow aura

**Pathoma Tab:**
- Chapter list with expand/collapse spring animation
- Video play icon pulses on chapters not yet watched

**UWorld Tab:**
- Subject blocks with animated correct % stat
- "Add Session" → bottom sheet with animated input fields

---

### SCREEN 4: Revision Hub
Calm, focused, distraction-free flip card SRS system.

**Mode toggle:** "Morning / Evening" — liquid pill morphs between states

**Revision card (hero element):**
- Full-width liquid glass card with heavy blur
- Front → Back: 3D flip animation (180° Y-axis, spring physics, card thickens mid-flip)
- Card has subtle shimmer sweep animation on idle
- Swipe right = spring bounce → green glow → "Revised ✅" Lottie burst
- Swipe left = spring rubber band → "Skipped" with amber fade

**Progress strip:**
- Animated liquid fill progress bar
- All done → full screen Lottie star-burst + confetti + "Zero backlog. Clean slate. 🌟"

---

### SCREEN 5: Claude Import
AI-powered data import screen. Feels like a terminal from the future.

**Background:** Darker version of ambient gradient, subtle matrix-style indigo particle drift

**Code editor input area:**
- Liquid glass dark surface, monospace font, indigo cursor blink
- Line numbers on left, syntax-tinted JSON (keys in indigo, values in white)
- Typing animation — characters appear with micro spring pop

**Preview cards (after paste):**
- Each action card flies in with spring stagger:
  - "📖 Mark FA Pages 50–59 as Read"
  - "🧠 Anki done for Pages 46–49"
  - "📋 Add task: Cook lunch 13:00–15:00"
  - "📊 UWorld: Biochemistry 10Qs — 70% correct"
- Each card: liquid glass with colored left accent, animated checkmark on success

**Execute button:**
- Indigo gradient, pulsing glow
- On tap: loading spinner morphs → success → confetti Lottie explosion

---

### SCREEN 6: Analytics
Medical-dashboard quality data visualization. Every chart animates.

**Pace line chart (hero):**
- Line draws itself left-to-right on load (800ms, ease-out)
- Area fill fades in beneath line with indigo gradient
- Target dashed line (amber) draws simultaneously
- Data point dots pop in with spring scale after line finishes

**Exam Projection cards:**
- Two side-by-side liquid glass cards
- "At 8.3/day: May 8 ⚠️" vs "At 10/day: May 1 ✅"
- Each card has a tiny animated timeline bar

**Subject radial mini charts (row of 6):**
- Each donut arc animates with spring overshoot
- Center % counts up
- Hover/tap → card scales up 1.05 with glow

**GitHub-style heatmap:**
- Cells fade in with stagger (left to right, row by row)
- Indigo intensity gradient
- Tap cell → tooltip floats up with spring

---

### SCREEN 7: Time Logger
Auto and manual time tracking.

**Top stat:** "Total today: 5h 40min" — count-up animation, large Inter Bold
**Entry list:** Auto-logged entries slide in with stagger on load
**Manual entry FAB:** Pulsing glow → bottom sheet with animated time pickers
**Category chips:** Liquid pill selection with slide-fill animation

---

### SCREEN 8: Settings
Rich, animated, premium settings — NOT grey iOS stock.

**Section headers:** Subtle animated indigo underline draws on scroll into view

1. **Exam Dates** — date pickers with liquid glass calendar sheets
2. **Prayer Times** — 5 rows, each time tap opens animated liquid glass time picker
3. **Sleep & Wake** — time pickers with animated arc clock visual
4. **Daily Goals** — number steppers with spring bounce on increment/decrement
5. **Navigation** — drag-to-reorder with spring haptic placeholder animation
6. **Backup** — animated toggle with success Lottie on backup complete
7. **Appearance** — theme switcher: tapping Light/Dark/System animates a live preview card morphing between themes

---

## 💎 GLOBAL MICRO-INTERACTION RULES

- **Every tap:** scale to 0.97 with spring bounce back (8ms response)
- **Every scroll:** momentum with slight parallax on hero cards (cards scroll 0.85x speed)
- **Pull to refresh:** custom indigo spinner with spring elastic pull
- **Empty states:** Lottie animation (soft floating illustration, not generic)
- **Error states:** card shakes horizontally 3× with spring (like iPhone wrong passcode)
- **Loading:** shimmer wave in lavender-indigo, never a generic spinner
- **All modals/sheets:** slide up with spring overshoot, backdrop blurs in simultaneously
- **Number changes:** old number slides up and out, new number slides up and in (slot machine style)

---

## 📐 LAYOUT RULES

- Screen padding: 20px horizontal
- Card padding: 20px internal
- Gap between cards: 16px
- Bottom nav: 72px + safe area, floating pill, heavy liquid glass
- Status bar: transparent always
- Safe area: respected (iPhone notch + Android cutout)
- Minimum touch target: 44×44px

---

## 🎯 DELIVERABLES

1. All 8 screens × 2 modes = 16 artboards
2. Component library: buttons, chips, progress bars, liquid glass cards, bottom nav, FAB, sheets
3. Color styles: primary, secondary, background, surface, success, warning, danger, text-primary, text-secondary, glow
4. Text styles: heading-xl, heading-lg, heading-md, body-md, body-sm, label, caption
5. Auto Layout on ALL components
6. Prototype: bottom nav, FAB, tab switches, card taps, swipe gestures

---

## ❌ DO NOT

- Use solid opaque cards — everything must be liquid glass
- Use static backgrounds — the background must always be an animated aurora mesh
- Use Material Design blue or flat shadows
- Use pure #000000 or #FFFFFF
- Add any screens not listed
- Use more than 2 font families
- Make anything look like a generic to-do or health app
- Use placeholder avatars or stock icons

---

This is Arsh's personal medical exam OS — built for USMLE Step 1 and FMGE preparation. The design must feel like Apple's iOS 26 Liquid Glass UI crossed with a Bloomberg Terminal crossed with Linear.app. Every pixel breathes. Every interaction has spring physics. Every screen feels like the future of mobile UI.
