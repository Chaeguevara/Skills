# AdSense + Next.js — extended reference

## Full working layout.tsx (App Router, Pattern B = recommended)

```tsx
// src/app/layout.tsx
import type { Metadata, Viewport } from "next";
import Script from "next/script";
import "./globals.css";

const adsenseClient = process.env.NEXT_PUBLIC_ADSENSE_CLIENT;

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <head>
        {/* preconnect to make the lazy-loaded AdSense fast when it kicks in */}
        {adsenseClient && (
          <link
            rel="preconnect"
            href="https://pagead2.googlesyndication.com"
            crossOrigin="anonymous"
          />
        )}
      </head>
      <body>
        {children}
        {/* DOM injection — no data-nscript on the AdSense tag itself */}
        {adsenseClient && (
          <Script id="adsense-defer" strategy="lazyOnload">
            {`(function(){
              var s=document.createElement('script');
              s.async=true;
              s.crossOrigin='anonymous';
              s.src='https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${adsenseClient}';
              document.head.appendChild(s);
            })();`}
          </Script>
        )}
      </body>
    </html>
  );
}
```

## In-content ad slot (after AdSense script is loaded)

```tsx
"use client";
import { useEffect, useRef } from "react";

declare global {
  interface Window {
    adsbygoogle?: unknown[];
  }
}

export function InContentAd({ slot }: { slot: string }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
    } catch {
      // adsbygoogle not loaded yet (lazy strategy) — retry after load event
      const onLoad = () => {
        try {
          (window.adsbygoogle = window.adsbygoogle || []).push({});
        } catch {}
      };
      window.addEventListener("load", onLoad, { once: true });
      return () => window.removeEventListener("load", onLoad);
    }
  }, []);

  return (
    <ins
      ref={ref as never}
      className="adsbygoogle"
      style={{ display: "block" }}
      data-ad-client={process.env.NEXT_PUBLIC_ADSENSE_CLIENT}
      data-ad-slot={slot}
      data-ad-format="auto"
      data-full-width-responsive="true"
    />
  );
}
```

**Reserve height to avoid CLS**: wrap `<ins>` in a fixed-height container (e.g. `min-h-[280px]`) so the ad slot doesn't shift content when fill happens.

## ads.txt template

`public/ads.txt`:

```
google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
```

The publisher ID must match `NEXT_PUBLIC_ADSENSE_CLIENT` (without the `ca-pub-` prefix).

## Verification

After deploy:

```bash
# AdSense crawler can find your ads.txt
curl -sI https://your-domain.com/ads.txt
# Status 200, content-type text/plain

# AdSense script is reachable
curl -sI "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-XXX"
# Status 200

# In browser console (after page idle):
> typeof adsbygoogle
"object"  # not "undefined" — script loaded
```

## Common AdSense rejection causes (separate from the data-nscript issue)

- Missing `ads.txt` — AdSense reports "Earnings at risk" within 24h of detection
- Site has < 30 indexed pages — wait for SEO maturity before applying
- Pages don't have substantial unique content — auto-ads policy review fails
- HTTPS misconfig — AdSense requires valid TLS

## Why `next/script` adds `data-nscript`

`next/script`'s purpose is to manage script lifecycle (avoid duplicate loads on client-side navigation, support `onLoad`, etc). It tags inserted elements with `data-nscript="<strategy>"` so its runtime can identify and dedupe them.

This identifier breaks AdSense's tag verifier, which strictly compares the script tag's attribute set against a known whitelist. AdSense's tag whitelist includes `async`, `src`, `crossorigin` — but not `data-nscript`. The verifier reports "head tag doesn't support data-nscript attribute" and refuses to validate.

There's no way to opt out of `data-nscript` from `next/script`. Hence: use raw `<script>` JSX, or inject via DOM as in Pattern B.
