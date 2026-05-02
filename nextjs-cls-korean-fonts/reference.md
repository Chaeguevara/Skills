# Korean fonts + CLS — extended reference

## Common Korean fonts and recommended next/font config

```ts
// All these use the same display: "optional", preload: false pattern.

// 1. Noto Sans KR (Google Fonts) — most common, broad weight range
import { Noto_Sans_KR } from "next/font/google";
const notoSansKr = Noto_Sans_KR({
  variable: "--font-sans-kr",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  display: "optional",
  preload: false,
});

// 2. Pretendard — popular Korean variable font, hosted at fonts.gstatic.com
//    (unofficially via npm package or self-hosted)
//    via next/font/local for the .woff2 file:
import localFont from "next/font/local";
const pretendard = localFont({
  src: [
    { path: "./fonts/Pretendard-Regular.woff2", weight: "400" },
    { path: "./fonts/Pretendard-Medium.woff2", weight: "500" },
    { path: "./fonts/Pretendard-SemiBold.woff2", weight: "600" },
    { path: "./fonts/Pretendard-Bold.woff2", weight: "700" },
  ],
  variable: "--font-sans-kr",
  display: "optional",
  preload: false,
});

// 3. Spoqa Han Sans Neo — also common, GPL-permissive
//    Self-host as woff2 via next/font/local, same pattern as Pretendard.
```

## CSS fallback chain

```css
/* globals.css */
@theme inline {
  --font-sans:
    var(--font-sans-kr),
    /* Korean OS fallbacks first — these look native */
    "Apple SD Gothic Neo",     /* macOS / iOS */
    "Pretendard",              /* if user has Pretendard installed */
    "Malgun Gothic",           /* Windows */
    "Noto Sans KR",            /* fallback if Google Fonts cached */
    /* Latin fallbacks */
    system-ui, -apple-system, sans-serif;
}

html, body {
  font-family: var(--font-sans);
  /* keep-all prevents Korean text from wrapping mid-syllable */
  word-break: keep-all;
  -webkit-text-size-adjust: 100%;
}
```

The fallback chain matters: if `display: optional` keeps the fallback, you want the fallback to look as close to the target as possible. Apple SD Gothic Neo / Malgun Gothic are clean Korean system fonts — most users won't notice the substitution.

## Why subsetting Korean Unicode doesn't help

| Subset attempt | Glyph count | Reality |
|---|---|---|
| `subsets: ["latin"]` | ~250 | Korean syllables fall through to OS fallback anyway |
| `unicode-range: U+AC00-U+D7AF` | ~11,000 | That's almost the entire Hangul syllabic block |
| Common 1,000 syllables | ~1,000 | Misses 90%+ of words; visible style mismatch when fallback hits |
| Variable font (Pretendard) | full | Smaller in total bytes than Noto Sans KR but still 600KB-1MB |

The fundamental issue: Korean has 11,172 precomposed Hangul syllables in regular use. There's no meaningful "popular subset" that doesn't visibly degrade.

## Verifying CLS

```bash
# 1. Lighthouse mobile (PageSpeed Insights uses Slow 4G + Moto G Power)
npx lighthouse https://your-site.com --view --form-factor=mobile

# 2. Vercel Speed Insights — P75 on real users
# Dashboard → Speed Insights → CLS metric
```

In DevTools → Performance panel → record a page load → look at "Layout Shift" entries. If you see them clustered around the time fonts finish loading, the swap was the culprit.

## Side effects of `display: "optional"`

- **First-time visitors on slow networks**: see fallback for the entire page. Acceptable because Korean OS fonts look native.
- **Returning visitors (cached)**: see the target font instantly, no swap.
- **Network panel**: Noto Sans KR woff2 still gets fetched; just not blocking render.

If you really need the target font on first visit (brand-critical typography), switch to `display: "swap"` and accept some CLS. There's no free lunch — Korean fonts are big.

## Related: don't preload large Korean woff2

```ts
// ❌ preload: true with a 1-2MB Korean woff2 → tanks LCP on mobile
preload: true,

// ✅ default
preload: false,
```

`preload: true` triggers `<link rel="preload">` which the browser treats as critical. For a font that's 10x larger than your CSS bundle, that's almost always wrong.
