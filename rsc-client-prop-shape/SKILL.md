---
name: rsc-client-prop-shape
description: Decide what shape of data to send from a Next.js Server Component to a Client Component. Triggers when about to pass a large server-loaded dataset (parsed JSON, DB query result, computed map) as a prop to a "use client" component.
disable-model-invocation: false
---

# RSC → client prop shape

## The trap

Server Components can `import fs` and load big JSON / run heavy compute. When you pass that result as a prop to a `"use client"` child, the **entire serialized prop ships in the page HTML** as part of the RSC payload.

A 1 MB JSON object passed as a prop = 1 MB of inline JSON in the HTML response = bigger TTFB, bigger LCP, more bytes parsed before hydration.

## Symptoms

- "First Load JS" stays small but page HTML response is huge
- Lighthouse complains about "Avoid huge document size" or "Reduce initial HTML"
- Network tab shows the page document at hundreds of KB

## Fix: project to the smallest shape the client actually needs

Before passing a server prop, ask: **does the client really need every field?**

```ts
// ❌ Server component
const fullData = loadDeepJoinedData();  // 1MB nested objects with 20 fields
return <ClientView data={fullData} />;

// ✅ Compact projection — only what the UI uses
type CompactRow = { id: string; price: number; lat: number; lng: number };
const compact: Record<string, CompactRow> = {};
for (const row of fullData) {
  compact[row.id] = { id: row.id, price: row.price, lat: row.lat, lng: row.lng };
}
return <ClientView data={compact} />;
```

A projection from 1 MB to 15 KB is common — keep only fields used in the client render path.

## Pre-compute on the server when possible

If a derived value is needed by the client (e.g. averages, normalized vectors, classifications), compute it server-side once and pass the result. Don't ship raw data + the derivation logic to the client.

```ts
// ✅ Server pre-computes; client just renders
const districtAvg: Record<string, number> = computeDistrictAverages(rawCenters);
return <ClientMap centers={lightCenters} districtAvg={districtAvg} />;
```

## Verify

```bash
# In dev: Network tab → click main page document → Headers → Content-Length
# Should be < 100KB for a static-ish page.
# Or:
curl -s http://localhost:3000/path | wc -c
```

If document size is large, check the RSC payload (the giant `<script>` blob with `self.__next_f.push(...)` lines) — that's where serialized props live.

## When you genuinely need all the data

Some interactive maps/graphs do need the full dataset client-side. In that case:
- Fetch it client-side from a JSON file (cacheable by CDN, separate from HTML)
- `fetch('/data/centers.json')` in a `useEffect`
- Page HTML stays small; data loads in parallel and is cached separately
