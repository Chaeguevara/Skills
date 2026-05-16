---
name: nextjs-static-route-bundle
description: Move large client-component props to a static route handler so the page HTML stays small. Use force-static + revalidate:false on a JSON route, then client fetch with cache:"force-cache". Triggers when an SSG page's HTML is bloated by serialized RSC payload (centers/items/dataset arrays > 100KB).
---

# Static route bundle for client data

**Bundled tool** (in this skill directory):
- `route-template.ts` — copy-paste-ready route handler + matching client `useEffect` fetch pattern with loading/error/retry states. Includes inline JSX comments noting why each piece exists.

## When to use

- Next.js App Router page passes large dataset (parsed JSON, computed map, 400+ items) to a `"use client"` component.
- The dataset becomes part of the RSC payload → page HTML balloons (e.g. 1MB).
- Lighthouse flags TBT / LCP because hydration parses huge serialized props.

## The pattern

### 1. Create static JSON route handler

```ts
// src/app/data/foo-bundle.json/route.ts
import { NextResponse } from "next/server";
import { loadFooData } from "@/lib/foo";

export const dynamic = "force-static";   // built once, served from CDN
export const revalidate = false;          // never re-validate

export function GET() {
  const items = loadFooData();
  // Optionally pre-compute heavy derivatives at build time so client doesn't.
  return NextResponse.json({ items, /* derived fields */ });
}
```

### 2. Client component fetches it

```tsx
"use client";
const [bundle, setBundle] = useState<Bundle | null>(null);
const [error, setError] = useState<string | null>(null);
const [attempt, setAttempt] = useState(0);

useEffect(() => {
  let aborted = false;
  fetch("/data/foo-bundle.json", { cache: "force-cache" })
    .then((r) => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); })
    .then((data) => { if (!aborted) setBundle(data); })
    .catch((err) => { if (!aborted) setError(err.message); });
  return () => { aborted = true; };
}, [attempt]); // attempt for manual retry
```

### 3. Render explicit loading + error states

```tsx
if (!bundle && !error) return <LoadingSkeleton />;
if (error) return <ErrorWithRetry onRetry={() => setAttempt(n => n+1)} />;
return <RealUI bundle={bundle} />;
```

Without explicit loading state, "0 results" flashes during fetch and users assume bug.

## Why it works

- **Build-time computation**: `force-static` generates the JSON file once at build, served from Vercel/CDN. Effectively free.
- **HTML stays tiny**: page HTML no longer carries serialized data. RSC payload stays under 50KB.
- **Cache**: `force-cache` lets browser memo for instant subsequent loads.
- **Pre-compute derivatives** in the route handler (averages, vectors, grades) so client just renders.

## Real case: 테마지도

`src/app/data/postpartum-bundle.json/route.ts` — 472 centers + nearbyMeta + vectors + hospitals + districtAvgs + grades. Page HTML: 1MB → 27KB.

## Anti-patterns

- ❌ Passing huge data as `"use client"` component prop ("just one render").
- ❌ Client-side `fetch()` to upstream API at runtime (defeats SSG, hits rate limits).
- ❌ Forgetting the loading state — users see "0 results" and think the page is broken.
- ❌ `dynamic="auto"` (default) on a /data/ route — Next.js may decide to render dynamically per request.

## Checklist

- [ ] Route file under `src/app/<path>/route.ts`
- [ ] `export const dynamic = "force-static"`
- [ ] `export const revalidate = false`
- [ ] Client fetch with `cache: "force-cache"`
- [ ] Loading + error states distinct from "empty" state
- [ ] Manual retry mechanism (`setAttempt`) for transient failures
