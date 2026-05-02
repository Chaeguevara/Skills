# useSearchParams + SSG — extended reference

## Decision tree

```
Need to read URL query param in App Router?
│
├─ Page is SSG (no `dynamic`, no `revalidate`)?
│  │
│  ├─ Param affects SEO / above-fold layout?
│  │   → Suspense + useSearchParams (page becomes partially dynamic)
│  │
│  └─ Param is cosmetic / behavioral / debug?
│      → window.location.search in useEffect (workaround)
│
└─ Page is dynamic (force-dynamic)?
   → useSearchParams direct, no Suspense needed (already dynamic)
```

## Reusable hook (drop in `src/lib/use-static-search-param.ts`)

```ts
"use client";
import { useEffect, useState } from "react";

/**
 * Read a query param without triggering Next.js's "useSearchParams() should
 * be wrapped in a suspense boundary" SSG opt-out. Reads window.location once
 * after mount.
 *
 * Trade-off: the value is null on first render (SSR + first hydration tick).
 * Use only for cosmetic/behavioral flags where flicker is acceptable.
 */
export function useStaticSearchParam(key: string): string | null {
  const [value, setValue] = useState<string | null>(null);
  useEffect(() => {
    if (typeof window === "undefined") return;
    const v = new URLSearchParams(window.location.search).get(key);
    if (v !== null) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setValue(v);
    }
  }, [key]);
  return value;
}
```

Usage:

```tsx
"use client";
import { useStaticSearchParam } from "@/lib/use-static-search-param";

export default function MyComponent() {
  const beta = useStaticSearchParam("beta");
  const isBeta = beta === "1";
  // ...
}
```

## Suspense path (when you really want the URL in SSR)

```tsx
// page.tsx (server component)
import { Suspense } from "react";
import { ClientFilteredView } from "./client";

export default function Page() {
  return (
    <Suspense fallback={<Skeleton />}>
      <ClientFilteredView />
    </Suspense>
  );
}

// client.tsx
"use client";
import { useSearchParams } from "next/navigation";

export function ClientFilteredView() {
  const params = useSearchParams();
  const filter = params.get("filter") ?? "all";
  // ...
}
```

What you give up:
- The page is no longer fully prerendered. Next renders the static shell + Suspense fallback at build time, then streams the dynamic part on request.
- For SEO-heavy pages this is usually fine — Google sees the fallback (often the right shape already) and crawls the streamed content too.

## Why `useSearchParams` is dynamic

Next 14+ App Router treats search params as dynamic input because:
- Search params are not part of the route — they vary per request
- Including them in the prerendered HTML would mean caching one variant and serving the wrong one to others
- Suspense is the marker that says "I know this part is dynamic, render it on demand"

Without the boundary, Next can't tell what's dynamic vs static, so it errors out.

## Patterns that look similar but aren't

```tsx
// ❌ usePathname() — also dynamic-ish but doesn't error in SSG
//    (pathname is part of the route, but if you read it client-side,
//     Next allows it because it's already known per route)

// ❌ useRouter().query — older Pages Router API; doesn't exist in App Router
```

## Real-world examples

- Feature flags via `?beta=1`, `?debug=1` — workaround pattern (cosmetic)
- A/B variant via `?v=B` — workaround pattern (set state, no SSR variant)
- Search results page with `?q=foo` — Suspense pattern (q affects content)
- Filter on a list page where filtered HTML is desired — Suspense pattern
