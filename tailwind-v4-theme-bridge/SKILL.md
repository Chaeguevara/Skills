---
name: tailwind-v4-theme-bridge
description: Expose CSS custom properties as Tailwind utility classes in v4 via @theme inline (--color-*, --shadow-*, --font-*). Triggers when you have a design token system in CSS variables but components still use raw rose-500/zinc-200/shadow-sm Tailwind utilities — this bridges them.
---

# Tailwind v4 theme bridge

## Problem

You define design tokens in `:root`:

```css
:root {
  --theme-500: #C96A75;
  --theme-700: #8E3F4C;
  --shadow-soft-2: 0 4px 12px rgba(...);
}
```

But component code keeps using raw Tailwind utilities:

```tsx
<div className="bg-rose-500 shadow-sm">
```

Tokens are defined but unused. Components remain off-system.

## The bridge

Tailwind v4 lets you expose CSS variables as utility values via `@theme inline`:

```css
@import "tailwindcss";

@theme inline {
  --font-sans: -apple-system, BlinkMacSystemFont, ...;

  /* Color palette → bg-theme-500, text-theme-700, border-theme-100 etc. */
  --color-theme-50:  #FBF0F0;
  --color-theme-100: #F4DCDD;
  --color-theme-300: #E5A8AA;
  --color-theme-500: #C96A75;
  --color-theme-700: #8E3F4C;
  --color-theme-tint: #FDF7F8;

  /* Shadow scale → shadow-soft-1, shadow-soft-2 etc. */
  --shadow-soft-1: 0 1px 2px rgba(15,17,21,0.04);
  --shadow-soft-2: 0 4px 12px rgba(15,17,21,0.06), 0 1px 2px rgba(15,17,21,0.04);
  --shadow-soft-3: 0 12px 32px rgba(15,17,21,0.10);
  --shadow-soft-pop: 0 20px 60px rgba(15,17,21,0.16);
}
```

Now components can use them as utilities:

```tsx
<div className="bg-theme-50 text-theme-700 shadow-soft-2 hover:bg-theme-100">
```

## Naming convention

Tailwind generates utilities from `--{prefix}-{name}` namespaces:

| Prefix      | Utilities generated                                |
| ----------- | -------------------------------------------------- |
| `--color-*` | `bg-*`, `text-*`, `border-*`, `ring-*`, `divide-*` |
| `--shadow-*`| `shadow-*`                                         |
| `--font-*`  | `font-*` (font-family)                             |
| `--text-*`  | `text-*` (font-size)                               |
| `--spacing-*`| `p-*`, `m-*`, `gap-*`, etc.                       |
| `--radius-*`| `rounded-*`                                        |

## Migration strategy — keep both

Don't rip out raw Tailwind colors. Migrate gradually:

```tsx
// Before
<div className="bg-rose-500 hover:bg-rose-600 shadow-sm">

// After (gradual — change rose to theme as you touch components)
<div className="bg-theme-500 hover:bg-theme-700 shadow-soft-1">
```

Keep `:root` legacy variables (`--theme-500`, `--sh-2`) too — for inline styles where Tailwind utilities don't fit:

```tsx
<div style={{ background: "linear-gradient(135deg, var(--theme-300), var(--theme-500))" }}>
```

## Why bother?

1. **System enforcement** — designer changes `--color-theme-500` once, every `bg-theme-500` component updates.
2. **Dark mode ready** — switch token values via `[data-theme="dark"]`, every utility responds.
3. **Multi-theme** — postpartum 로즈 / 부동산 인디고 / 등산 모스 gr린 — same component, different `data-theme` attribute, different palette.
4. **Discoverability** — `bg-theme-500` reads as semantic; `bg-rose-500` is generic.

## Real case — 테마지도

`src/app/globals.css` exposes `--color-theme-{50,100,300,500,700,ink,tint}` and `--shadow-soft-{1,2,3,pop}`. Components migrated from `bg-rose-500 shadow-sm` to `bg-theme-500 shadow-soft-1`. CenterCard, GradeBadge, TopFacilities, MetaCard now share a theme-aware token system. Adding "moto" or "realestate" theme later = define `[data-theme="moto"] { --color-theme-500: #9C6F1F; ... }`. Zero component changes.

## Anti-patterns

- ❌ **Defining all tokens in legacy `:root` only** — they're useful but not Tailwind-discoverable.
- ❌ **Defining same value twice** — keep one source of truth. If `@theme inline` has it, `:root` doesn't need it. (We keep both for now during migration; long-term consolidate.)
- ❌ **Hardcoding hex everywhere** — breaks the bridge. Always reference token by name.
- ❌ **Forgetting Tailwind expects `--color-*` prefix specifically** — `--theme-color-500` won't generate utilities.
