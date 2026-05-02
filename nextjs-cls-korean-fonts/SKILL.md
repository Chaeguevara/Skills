---
name: nextjs-cls-korean-fonts
description: Fix Cumulative Layout Shift (CLS) in Next.js sites that use Korean web fonts via next/font/google. Triggers when seeing high CLS scores in Lighthouse, Vercel Speed Insights flagging "Poor CLS", or visible font-swap reflow on Korean text.
disable-model-invocation: false
---

# Korean fonts + CLS

## Why Korean fonts CLS so badly

`next/font/google` with `display: "swap"` (the default in many examples) renders fallback first, then swaps to Noto Sans KR / Pretendard / etc. when ready.

The fallback is usually a Latin-shaped system font. Korean glyphs in the fallback come from the OS's secondary font (Apple SD Gothic Neo on macOS, Malgun Gothic on Windows). When the swap happens:

- Glyph widths change (esp. mixed Korean+Latin lines)
- Line heights change
- Whole pages reflow → CLS up to 0.3+ on text-heavy pages

The Latin subset trick (`subsets: ["latin"]`) doesn't help because Korean characters fall through to the OS font on the fallback path anyway.

## Fix: `display: "optional"` + no preload

```ts
import { Noto_Sans_KR } from "next/font/google";

const notoSansKr = Noto_Sans_KR({
  variable: "--font-sans-kr",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  display: "optional",   // ← key change
  preload: false,         // ← Korean fonts are 1-2MB, preloading hurts LCP
});
```

`display: "optional"` means: if the font isn't ready within ~100ms, browser keeps fallback for the entire page lifetime (no swap). On a return visit (cached) it's instant. CLS goes to ~0.

Trade-off: first-time visitors may see fallback font on slow networks. Acceptable because Korean OS fonts (Apple SD Gothic Neo, Pretendard if installed) look native. Better than visible reflow.

## Don't try

- ❌ Subsetting Korean Unicode ranges via `unicode-range` to make the font smaller — modern Korean (한글) has 11,172 syllables. There's no meaningful subset.
- ❌ Using `font-display: swap` and hoping CLS settles — it won't, the size delta is too big.
- ❌ Self-hosting and preloading the woff2 — 1-2MB preload destroys LCP on mobile.

## Verify

```bash
# In browser DevTools → Lighthouse mobile → Performance
# Look for CLS metric and "Layout shift culprits" insight
```

After this fix, CLS from font swap should be 0. Remaining CLS comes from images without dimensions, ads, or JS-driven layout (see `nextjs-cls-mobile-layout` skill).
