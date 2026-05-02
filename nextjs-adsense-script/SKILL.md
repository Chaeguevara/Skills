---
name: nextjs-adsense-script
description: Add Google AdSense to a Next.js App Router site without breaking AdSense validation. Triggers when adding AdSense, fixing "data-nscript attribute" errors, or wiring up adsbygoogle.js script tag.
disable-model-invocation: false
---

# AdSense in Next.js — script tag rules

## Don't use `next/script` for `adsbygoogle.js`

`next/script` adds `data-nscript="..."` to the rendered tag. AdSense's tag validator rejects this with:

> AdSense head tag doesn't support data-nscript attribute

This breaks the auto-ad / verification flow.

## Correct patterns (pick one)

### A. Inline `<script>` JSX in `<head>` (simplest, blocks render less than you'd expect because async)

```tsx
// app/layout.tsx
<html>
  <head>
    {adsenseClient && (
      <script
        async
        src={`https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${adsenseClient}`}
        crossOrigin="anonymous"
      />
    )}
  </head>
  <body>...</body>
</html>
```

Notes: in App Router this raw `<script>` works. JSX uses `crossOrigin` (camelCase) which renders to `crossorigin`.

### B. Lazy injection via DOM (best for CWV — improves TBT/LCP)

Use `next/script` for a tiny inline bootstrap that creates the AdSense `<script>` itself. The injected tag has no `data-nscript`.

```tsx
import Script from "next/script";

<Script id="adsense-defer" strategy="lazyOnload">
  {`(function(){
    var s=document.createElement('script');
    s.async=true;
    s.crossOrigin='anonymous';
    s.src='https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${adsenseClient}';
    document.head.appendChild(s);
  })();`}
</Script>
```

Pair with `<link rel="preconnect" href="https://pagead2.googlesyndication.com" crossOrigin="anonymous" />` in `<head>` so the lazy load is fast when it kicks in.

## ads.txt

Always serve `public/ads.txt`:

```
google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
```

## Don't

- ❌ `<Script src="..adsbygoogle.js" />` — adds `data-nscript`, fails validation
- ❌ Putting the AdSense script in a client component — duplicates loads on navigation
- ❌ Forgetting `crossOrigin="anonymous"` — required by AdSense

## More

- `reference.md` — full layout.tsx for both patterns, in-content `<ins>` ad slot pattern, ads.txt details, why next/script adds `data-nscript`
- `scripts/audit.sh` — run from project root to check ads.txt presence, detect the anti-pattern, verify preconnect
  ```bash
  bash ~/.claude/skills/nextjs-adsense-script/scripts/audit.sh /path/to/project
  ```
