# RSC → client prop shape — extended reference

## How to figure out what the client really uses

Open the client component and search for every read of the prop:

```bash
# In the project root
grep -nE 'props\.data\.[a-zA-Z_]+|data\.[a-zA-Z_]+|\bdata\b' src/components/MyClient.tsx
```

List the fields actually read. That's your projection schema. Anything not on that list does not need to ship.

## Compact projection helper pattern

```ts
// src/lib/projections.ts

/**
 * Project an array of records to a compact map keyed by id.
 * Use in server components before passing data to client.
 */
export function projectById<T extends { id: string }, U>(
  rows: T[],
  pick: (r: T) => U,
): Record<string, U> {
  const out: Record<string, U> = {};
  for (const r of rows) out[r.id] = pick(r);
  return out;
}
```

```ts
// In server component (page.tsx)
import { projectById } from "@/lib/projections";
import { loadFullCenters } from "@/lib/data";

const centers = loadFullCenters();  // 1MB rich records
const compact = projectById(centers, (c) => ({
  id: c.id,
  name: c.name,
  lat: c.position?.lat,
  lng: c.position?.lng,
  price: c.priceStandardManwon,
}));
// 472 × ~50 bytes ≈ 25KB

return <ClientMap centers={compact} />;
```

## When the client needs heavy data: split fetch from page

If the client genuinely needs the full dataset (interactive filtering, complex viz):

### Pattern A — fetch from a JSON endpoint

```ts
// app/data/centers.json/route.ts
import { NextResponse } from "next/server";
import { loadFullCenters } from "@/lib/data";

export const dynamic = "force-static";
export const revalidate = false;

export function GET() {
  return NextResponse.json(loadFullCenters());
}
```

```tsx
// client component
"use client";
import { useEffect, useState } from "react";

export function HeavyClient() {
  const [centers, setCenters] = useState<Center[] | null>(null);
  useEffect(() => {
    fetch("/data/centers.json")
      .then((r) => r.json())
      .then(setCenters);
  }, []);
  if (!centers) return <Skeleton />;
  return <Map centers={centers} />;
}
```

Trade-offs:
- ✅ Page HTML stays small → fast TTFB / FCP / LCP
- ✅ JSON is cached separately by CDN → repeat visits free
- ✅ No SSR cost for the dataset
- ❌ Loading state visible on first visit
- ❌ One extra request

### Pattern B — emit JSON to public/ at build time

```ts
// scripts/emit-public-data.mts
import { writeFileSync } from "node:fs";
import { loadFullCenters } from "../src/lib/data.js";

writeFileSync("public/data/centers.json", JSON.stringify(loadFullCenters()));
```

Add to `prebuild` script in `package.json`. Now `/data/centers.json` is a static asset (best CDN behavior).

## Measuring RSC payload size

```bash
# Local dev — start server, then in another shell
curl -s http://localhost:3000/your-route | wc -c
# Should generally be < 100KB for routes that ought to be lightweight

# Specifically the RSC payload (the giant <script>self.__next_f.push(...) blob)
curl -s http://localhost:3000/your-route | grep -c '__next_f.push'
# Many pushes is normal; what matters is total bytes
```

## Decision rubric

| Data size needed by client | Pattern |
|---|---|
| ≤ 30 KB after compaction | Pass as prop directly |
| 30 KB – 200 KB | Compact projection, pass as prop, OK |
| 200 KB – 2 MB | Split: fetch from `/data/*.json` route on mount |
| > 2 MB | Split + paginate / lazy / virtualize on the client |

These are rules of thumb. The right cutoff depends on whether the data is needed for FCP/LCP critical content.

## Common offenders

- Passing the full DB query result when the client only renders a list
- Passing nested objects that include a giant relations array (e.g. center → all reviews)
- Pre-computing every variant up front and shipping them all
- Passing `process.env.*` style config that should be inlined elsewhere

## Bonus: detecting the issue in CI

```bash
# Fail CI if any prerendered page exceeds X KB
for f in $(find .next/server/app -name "*.html"); do
  size=$(wc -c < "$f")
  if [[ $size -gt 200000 ]]; then
    echo "❌ $f is $size bytes — likely RSC payload too big"
    exit 1
  fi
done
```
