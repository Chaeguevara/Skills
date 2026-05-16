---
name: mobile-header-info-architecture
description: Mobile-first information architecture for page headers. On narrow viewports the header should carry the primary task only; secondary metadata moves below the fold (e.g., under the map, hero image, or first content block). Triggers when the header looks crowded on mobile, when stakeholders ask "왜 모바일이 무겁지?", when adding meta chips/filters/breadcrumbs, when Lighthouse mobile shows above-the-fold layout shift, or when designing a new domain landing page. Cross-project — applies to any responsive web app where the same header serves both desktop (~1024px+) and mobile (~375–414px).
disable-model-invocation: false
---

# Mobile Header Info Architecture

The desktop header has room for breadcrumb + title + meta chips + filter row + action buttons. Mobile doesn't. Shoving all of that into a narrow viewport pushes the primary task (map, search box, hero) below the fold, hurts CLS, and feels noisy.

## The pattern — primary on top, secondary below

**Header (visible on all sizes)** carries:
- One headline
- The primary action (search input, "지도 보기" CTA, or the map itself when the map IS the product)

**Secondary strip (mobile)** carries:
- Meta chips (region count, last-updated date, filter pills)
- Breadcrumb when it's nav-critical
- Counts, source attribution, side annotations

**Same content on desktop** sits inline in the header because there's room.

## Tailwind realization — `hidden md:contents`

The cleanest way to share JSX while changing the visual position:

```tsx
{/* Mobile: strip lives BELOW the map */}
{/* Desktop: same chips live INSIDE the header via md:contents */}

<header className="flex flex-col gap-2 md:flex-row md:items-baseline md:justify-between">
  <h1>전국 산후조리원 지도</h1>
  <div className="hidden md:contents">
    <MetaChips />
  </div>
</header>

<MapView />

<div className="md:hidden">
  {/* mobile-only strip */}
  <MetaChips />
</div>
```

`md:contents` makes the wrapper disappear at md+ so children become flex/grid items of the header. On mobile the `md:hidden` strip renders below the map. This avoids duplicate `<MetaChips>` mounts when both blocks are always rendered — pick one or the other.

### Alternative — single mount + CSS-only reorder

If `<MetaChips>` is stateful or expensive, mount once and reorder via flex order:

```tsx
<div className="flex flex-col">
  <h1 className="order-1">전국 산후조리원 지도</h1>
  <MapView className="order-2 md:order-3" />
  <MetaChips className="order-3 md:order-2 md:absolute md:top-4 md:right-4" />
</div>
```

Trade-off: `md:absolute` couples the chip layout to the header dimensions. Acceptable if the chip group is small.

## What goes in the primary-task slot

Decide per domain:

| Domain pattern | Primary slot on mobile |
|---|---|
| Map-centric (지도가 본체) | The map itself, full-width, header collapsed to title bar |
| Search-centric (검색이 본체) | Search input + 1–2 inline filters |
| Hero/landing | Hero image + 1 CTA |
| Article/guide | Title + TOC anchor or "scroll to first section" |

If the page has *both* a map and a search box, the search box wins above the fold because users still scroll for the map but won't scroll to find a search.

## What goes in the secondary strip

- "전국 N곳", "마지막 업데이트 YYYY-MM-DD", source attribution
- Filter chips that are "nice to have" — region, category, tier
- Breadcrumb when it's navigational; if it's only decorative, drop it on mobile
- Sort selector when there's a sensible default

## Red flags

- Mobile header taller than 200px when collapsed → too much in the header
- Above-the-fold doesn't show the primary task → information architecture failure, not a CSS problem
- Sticky header that covers >15% of the viewport when scrolling → competes with content
- "Add a chip" requests are accumulating → the strip is the right home, not the header

## Why this matters

- **CLS**: tall headers push the map / hero down, then JS hydrates and reflows. Smaller header = smaller layout shift.
- **LCP**: the primary task IS usually the LCP element. Push it down and LCP regresses.
- **Conversion**: users on mobile decide in 1–2 seconds whether the page does what they want. If the primary task isn't visible, they bounce.
- **Cognitive load**: chips and metadata are scannable when relevant; they're noise when they appear before the user knows what the page is for.

## Related

- Lighthouse "Largest Contentful Paint" mobile audit
- CLS / above-the-fold patterns
- The desktop-first instinct ("I have room, let me add more chips") is the trap this skill exists to interrupt
