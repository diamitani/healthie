# Healthie.ai — SaaS Unicorn Brand & Design System Specification

## 1. Brand Identity Overview

**Brand Name:** Healthie.ai  
**Tagline:** ROSTR Multi-Agent Health Document Intelligence  
**Positioning:** Premium Consumer Health & Medical Bill Intelligence SaaS  
**Market Tier:** $9/month (Starter) & $19/month (Pro Vault)  
**Aesthetic Theme:** SaaS Unicorn — Glowing neon teal/emerald gradients, soft glassmorphism overlays, warm responsive dark/light modes, accessible typography.

---

## 2. Logo System

The official Healthie logo system is crafted as scalable vector graphics (SVG) under `/web/assets/brand/`:

| Logo Asset | Usage | Aspect Ratio / File |
|---|---|---|
| **Primary Horizontal** | Website Navbar, Marketing Headers, PDF Exports | 4:1 (`healthie-logo-primary-horizontal.svg`) |
| **App Icon / Favicon** | iOS App Icon, Favicon, Social Avatar, PWA | 1:1 (`healthie-logo-icon.svg`) |
| **Dark Mode Variant** | Dark Mode Navbar, Night Theme Footers | 4:1 (`healthie-logo-dark.svg`) |

### Logo Construction & Visual Metaphors
- **The Health Shield (`path`)**: Represents HIPAA-aligned security, trust, and patient record protection.
- **The Medical Pulse Cross**: Represents clinical accuracy, biomarker labs, and medical document extraction.
- **The AI Spark (`circle / star`)**: Represents the ROSTR Multi-Agent engine (PAL + RAG DAL PubMed literature grounding).
- **The Radiant Gradient (`#0d9488 → #0284c7 → #6366f1`)**: Represents modern SaaS Unicorn elegance and consumer energy.

---

## 3. Color Palette & HSL Design Tokens

### Primary Brand Gradients
- `var(--brand-gradient)`: `linear-gradient(135deg, #0d9488 0%, #0284c7 50%, #6366f1 100%)`
- `var(--brand-gradient-hover)`: `linear-gradient(135deg, #0f766e 0%, #0369a1 50%, #4f46e5 100%)`
- `var(--accent-glow)`: `radial-gradient(circle, rgba(13, 148, 136, 0.15) 0%, rgba(99, 102, 241, 0.05) 70%, transparent 100%)`

### Semantic Tokens (Light Mode)
```css
:root {
  --color-primary: #0d9488;          /* Teal 600 */
  --color-primary-dark: #0f766e;     /* Teal 700 */
  --color-primary-light: #ccfbf1;    /* Teal 100 */

  --color-secondary: #6366f1;        /* Indigo 500 */
  --color-surface-bg: #f8fafc;       /* Slate 50 */
  --color-surface-card: #ffffff;     /* Pure White */
  --color-surface-alt: #f1f5f9;      /* Slate 100 */
  --color-border: #e2e8f0;           /* Slate 200 */

  --color-ink-main: #0f172a;         /* Slate 900 */
  --color-ink-muted: #475569;        /* Slate 600 */
  --color-ink-subtle: #94a3b8;       /* Slate 400 */

  --color-success: #10b981;          /* Emerald 500 */
  --color-warning: #f59e0b;          /* Amber 500 */
  --color-flag-anxiety: #f97316;     /* Orange 500 (Abnormal Flag) */
}
```

### Semantic Tokens (Dark Mode)
```css
html.dark {
  --color-surface-bg: #07090e;       /* Deep Obsidian */
  --color-surface-card: #111827;     /* Slate 900 */
  --color-surface-alt: #1f2937;      /* Slate 800 */
  --color-border: #1f2937;
  --color-ink-main: #f8fafc;
  --color-ink-muted: #94a3b8;
  --glass-bg: rgba(17, 24, 39, 0.85);
}
```

---

## 4. Typography Scale

- **Primary Sans (UI Body & Headings):** `Outfit`, `-apple-system`, `BlinkMacSystemFont`
- **Monospace (Data, Code, CPT, Ranges):** `IBM Plex Mono`, `monospace`
- **Serif Accent (Editorial Headings):** `Instrument Serif`, `Georgia`

| Scale Level | Font Size | Weight | Line Height | Tracking |
|---|---|---|---|---|
| **Hero Title** | 56px | 800 (Bold) | 1.1 | -1.5px |
| **Section Heading (H2)** | 36px | 800 | 1.2 | -0.5px |
| **Card Heading (H3/H4)** | 20px - 24px | 700 | 1.3 | 0px |
| **Body Text** | 15px - 16px | 400 / 500 | 1.6 | 0px |
| **Monospace / Code** | 12.5px - 14px | 500 / 600 | 1.5 | 0.5px |

---

## 5. Glassmorphism & Micro-Animations

- **Card Glass:** `background: rgba(255, 255, 255, 0.85); backdrop-filter: blur(16px);`
- **Unicorn Ambient Glow:** `box-shadow: 0 20px 40px -15px rgba(13, 148, 136, 0.25);`
- **Spring Transition:** `transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);`
- **Hover Motion:** `transform: translateY(-2px);`

---

## 6. Component Specs

### Button System (`.btn`)
- `.btn-primary`: Brand gradient background, white text, glowing unicorn shadow on hover.
- `.btn-secondary`: Slate background, slate text.
- `.btn-outline`: Transparent, 1px border, teal hover transition.
- `.btn-ghost`: Subtle hover background.

### Badge Component (`.badge`)
- `.badge-primary`: Soft teal tint with teal text.
- `.badge-secondary`: Soft indigo tint.
- `.badge-warning`: Orange flag for abnormal lab markers.

---

## 7. iOS Mobile PWA Adaptation

- **Viewport:** Native 390px iPhone width layout with touch-friendly 44px+ targets.
- **Bottom Navigation Bar:** Floating glassmorphism tab bar with Home, Vault, Doctor Plan, and Settings.
- **iOS Notch Compatible:** Built-in iPhone Notch clearance and PWA meta tags (`apple-mobile-web-app-capable`).
