---
name: nextjs-conditional-feature-bundling
description: Split Next.js client bundles so conditional features (?beta=1, admin mode, dialog/modal, "load more" tabs) only download when actually triggered. Triggers when seeing large `_app` or page chunks (200KB+), Lighthouse "Reduce unused JavaScript" with own-domain chunks, when adding feature flags, or when the same code ships to all users despite being used by < 10%.
disable-model-invocation: false
---

# Conditional feature bundling — `next/dynamic` + `import()`

## When to use

A feature is opt-in (URL param, button click, admin route, A/B variant) but its code ships in the main bundle to 100% of users. Examples from real projects:

- `?beta=1` recommendation system used by 1% of visitors
- Modal/dialog opened by < 5% of visits (calendar picker, image cropper, settings)
- Admin/dev panels gated by env or role
- Heavy chart/map libraries used only on certain pages or interactions

The fix: chunk-split with `next/dynamic` (components) or `import()` (libraries). The chunk only downloads when the trigger fires.

## Components — `next/dynamic`

```tsx
"use client";

import dynamic from "next/dynamic";
import { useState } from "react";

// Beta-only UI — chunk separated, downloads on first render
const RecommendBar = dynamic(() => import("./RecommendBar"), { ssr: false });
const RecommendResultCard = dynamic(() => import("./RecommendResultCard"), {
  ssr: false,
});

export default function Page() {
  const [isBeta, setIsBeta] = useState(false);
  // … detect ?beta=1, set isBeta
  return (
    <>
      {/* always-rendered base UI */}
      {isBeta && <RecommendBar />}
      {isBeta && <RecommendResultCard />}
    </>
  );
}
```

`ssr: false` skips SSR for the dynamic component — appropriate for behavior-driven UI that wouldn't render meaningfully on the server anyway. Saves SSR HTML weight too.

For SSR-friendly conditional rendering, drop `ssr: false` and provide a `loading` placeholder.

## Libraries — `import()` inside `useEffect`

`next/dynamic` is for components only. For pure JS libs (algorithms, formatters, validators), use the dynamic import expression:

```tsx
"use client";

import { useEffect, useState } from "react";

type RecommendationLib = typeof import("@/lib/parenting/recommendation");

export default function MapView() {
  const [isBeta, setIsBeta] = useState(false);
  // … detect beta

  // Library is only loaded when isBeta becomes true
  const [recLib, setRecLib] = useState<RecommendationLib | null>(null);
  useEffect(() => {
    if (!isBeta || recLib) return;
    let aborted = false;
    import("@/lib/parenting/recommendation").then((mod) => {
      if (!aborted) setRecLib(mod);
    });
    return () => {
      aborted = true;
    };
  }, [isBeta, recLib]);

  // Use the library — guard on null
  const result = useMemo(() => {
    if (!recLib || !someCondition) return null;
    return recLib.rankBySimilarity(/* ... */);
  }, [recLib, /* deps */]);
}
```

Key points:
- **Type the lib** with `typeof import(...)` — keeps TypeScript inference without dragging in runtime code
- **Use `useState`** to store the loaded module — re-renders when module arrives
- **Guard every usage** with null check — module is `null` until first load
- **Add `recLib` to useMemo deps** — re-compute after module arrives
- **Cleanup with `aborted` flag** — avoid setState on unmounted component

## What NOT to lazy-load

- Code on the LCP critical path — adds a network roundtrip before paint
- Code used by >50% of users — chunk overhead exceeds savings
- Tiny utilities (< 5KB) — HTTP/2 chunk overhead doesn't pay off

## Verify

```bash
# After build
npm run build
ls -lh .next/static/chunks/*.js | sort -k5 -h | tail -10
# Look for new tiny chunks (~5-30KB) that correspond to dynamic imports

# In browser DevTools → Coverage tab on first visit
# Confirm dynamic chunks are NOT in initial download
```

Lighthouse "Reduce unused JavaScript" insight should drop for own-domain chunks proportional to what you split out.

## More

- `scripts/find-conditional.sh` — scan for `&& <Component` JSX patterns where Component is statically imported, suggesting candidates to convert to `next/dynamic`
  ```bash
  bash ~/.claude/skills/nextjs-conditional-feature-bundling/scripts/find-conditional.sh /path/to/project
  ```
