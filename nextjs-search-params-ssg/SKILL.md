---
name: nextjs-search-params-ssg
description: Read URL query params in a Next.js page that's statically generated (SSG). Triggers when seeing "useSearchParams() should be wrapped in a suspense boundary" build errors, or when adding ?foo=bar gating to a static page.
disable-model-invocation: false
---

# `useSearchParams` in SSG pages

## The problem

Next.js App Router treats `useSearchParams()` as dynamic. In a fully static page (no `dynamic = "force-dynamic"`, no `revalidate`) it triggers:

> useSearchParams() should be wrapped in a suspense boundary

This breaks the build OR opts the entire page out of SSG.

## When it bites

- Feature flags via query string (`?beta=1`, `?debug=1`)
- Read-only filters that don't need to be in URL state for SEO
- A/B test variant detection

## Workaround: read `window.location.search` in `useEffect`

```tsx
"use client";

const [isBeta, setIsBeta] = useState(false);

useEffect(() => {
  if (typeof window === "undefined") return;
  const params = new URLSearchParams(window.location.search);
  if (params.get("beta") === "1") {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setIsBeta(true);
  }
}, []);
```

Trade-offs:
- ✅ Page stays fully SSG — no Suspense boundary needed
- ✅ Crawlers see static HTML; only client-side JS reads the param
- ❌ Brief flash before effect runs (1 frame). Acceptable for non-critical features.
- ❌ Need eslint disable for `react-hooks/set-state-in-effect`

## When to use Suspense instead

If the param affects SEO-critical content or above-the-fold layout, use the proper pattern:

```tsx
import { Suspense } from "react";

<Suspense fallback={<Skeleton />}>
  <ClientComponent />  {/* uses useSearchParams() inside */}
</Suspense>
```

Page becomes partially dynamic — search engines still see the fallback, but you trade some SSG benefits.

## Rule of thumb

Cosmetic / behavioral param (debug, beta, theme): `window.location` workaround.
Content-shape param (filter, sort that affects what gets rendered): Suspense + `useSearchParams`.
