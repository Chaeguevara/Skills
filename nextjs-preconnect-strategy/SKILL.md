---
name: nextjs-preconnect-strategy
description: Decide where and how many preconnect / dns-prefetch hints to add in a Next.js App Router site. Triggers when adding `<link rel="preconnect">`, when Lighthouse reports "Unused preconnect" or "Avoid more than 4 preconnects", or when 3rd-party scripts (Kakao SDK, AdSense, GA, Stripe, etc.) need handshake-cost optimization.
disable-model-invocation: false
---

# preconnect strategy

## Rules

1. **Max 4 preconnects per page.** Lighthouse warns above 4. Each preconnect costs a TCP+TLS handshake speculatively.
2. **Only preconnect to origins the page WILL request.** "Unused preconnect" is the most common Lighthouse warning here.
3. **Preconnect for resources on the LCP critical path; dns-prefetch for everything else.** preconnect = full handshake (~150ms savings). dns-prefetch = DNS lookup only (~30ms savings, but cheap).

## Where to put them

`<link rel="preconnect">` in App Router:

| Resource | Used on every page? | Where to put hint |
|---|---|---|
| Analytics (Vercel, GA, Plausible) | Yes | Root `app/layout.tsx` `<head>` — but use `dns-prefetch`, they're not LCP-critical |
| AdSense | Most pages | Root layout `<head>` `preconnect` — first ad request needs handshake fast |
| Map SDK (Kakao, Mapbox, Google Maps) | Only on map pages | Per-page `<link>` in the map page tsx, NOT root layout |
| CDN for tiles / images | Only when used | Per-page or page-group layout |
| Stripe / payment | Only on checkout | Checkout page only |

## Per-page preconnect in App Router

Yes, you can put `<link>` directly in a page component — Next 14+ hoists it to `<head>`:

```tsx
// app/maps/page.tsx (server component)
export default function MapPage() {
  return (
    <>
      <link rel="preconnect" href="https://map-sdk.example.com" crossOrigin="anonymous" />
      <link rel="preconnect" href="https://tile-cdn.example.com" crossOrigin="anonymous" />
      {/* page content */}
    </>
  );
}
```

For client components, the same works inside JSX. The `crossOrigin="anonymous"` is required for fonts and many SDK assets — match what the actual `<script crossorigin>` uses.

## What about `<head>` in app/layout.tsx?

It's fine for site-wide origins (analytics, AdSense). But putting per-route origins there (e.g. Kakao SDK on a non-map landing page) wastes the handshake AND triggers Lighthouse's "Unused preconnect" warning.

## dns-prefetch as a cheap fallback

When you're unsure whether the user will hit an origin, use dns-prefetch — costs almost nothing, just resolves DNS in advance.

```tsx
<link rel="dns-prefetch" href="https://maybe-used.example.com" />
```

Use cases:
- Origins used on a sub-page the user might navigate to
- 3rd-party scripts loaded with `lazyOnload` strategy (their fetch happens late; just dns-prefetch is enough)

## Common mistakes

- ❌ Preconnecting to your own domain (e.g. `<link rel="preconnect" href="/">`) — browsers already keep this connection warm
- ❌ Adding 5-6 preconnects "just in case" — Lighthouse penalizes; some browsers limit total speculative connections
- ❌ Forgetting `crossOrigin="anonymous"` — for CORS-required resources, the preconnect doesn't apply
- ❌ Putting Kakao/Maps preconnect in root layout when only one route uses the map

## crossorigin mismatch — the silent killer

The most subtle bug: **preconnect's `crossorigin` attribute MUST match how the actual resource request is made**, otherwise the browser opens a SECOND connection and your preconnect was wasted.

| Resource type | Actual fetch behavior | Required preconnect |
|---|---|---|
| `<script src="...">` (no `crossorigin`) | sends without `Origin` header | `<link rel="preconnect" href="...">` (no crossOrigin) |
| `<script src="..." crossorigin="anonymous">` | sends `Origin: ...` | `<link rel="preconnect" crossOrigin="anonymous">` |
| `<img src="..." crossorigin="anonymous">` | sends `Origin: ...` | `<link rel="preconnect" crossOrigin="anonymous">` |
| `<img src="...">` (no crossorigin) | no `Origin` header | `<link rel="preconnect" href="...">` (no crossOrigin) |
| `next/font/google` woff2 | always `crossorigin="anonymous"` | `<link rel="preconnect" crossOrigin="anonymous">` |
| AdSense `adsbygoogle.js` | always `crossorigin="anonymous"` (required) | `<link rel="preconnect" crossOrigin="anonymous">` |

Lighthouse reports this as **"Unused preconnect. Check that the crossorigin attribute is used properly."** even though the origin is correct.

### Real-world example (Kakao Map)

Kakao Maps SDK script is loaded WITHOUT crossorigin (the SDK loader appends a plain `<script src="...">`). Tile PNGs are also fetched without crossorigin. So:

```tsx
// ❌ Wasted preconnect — mismatch
<link rel="preconnect" href="https://dapi.kakao.com" crossOrigin="anonymous" />
<link rel="preconnect" href="https://t1.daumcdn.net" crossOrigin="anonymous" />

// ✅ Matches the actual SDK + tile requests
<link rel="preconnect" href="https://dapi.kakao.com" />
<link rel="preconnect" href="https://t1.daumcdn.net" />
<link rel="preconnect" href="https://mts.daumcdn.net" />
```

### How to verify

1. **Lighthouse "Preconnected origins" insight** — flagged as "Unused preconnect" if mismatch
2. **DevTools Network tab** — first request to the origin should show `Connection: 0ms` (already established). If it shows full handshake (DNS+TLS), preconnect didn't work.
3. **`Connection: keep-alive`** alone isn't enough — the connection must be opened on the SAME origin AND the SAME credentials mode.

### Quick check

Before adding `crossOrigin="anonymous"`, find a real network request to that origin and look at its `crossorigin` attribute / `Sec-Fetch-Mode` header. Match exactly.

## Verify

```bash
# Lighthouse insights:
# - "Preconnected origins" — should list only origins the page actually used
# - "Preconnect candidates" — Lighthouse will suggest which origins WOULD benefit
# - "Avoid more than 4 preconnects" — limit total

# Browser network tab:
# Connection time for preconnected origin's first request should be ~0ms
# (DNS+TLS already done before request)
```
