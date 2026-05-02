---
name: nextjs-cls-korean-fonts
description: Korean web fonts in Next.js — CLS and LCP trade-offs. Triggers when seeing high CLS, Poor LCP on mobile, "Render blocking requests" with woff2 in critical path, or when adding next/font/google for a Korean font.
disable-model-invocation: false
---

# Korean fonts in Next.js — CLS and LCP

## TL;DR — pick one

| Goal | Choice |
|---|---|
| Brand-critical typography (cared more about visual identity than perf) | next/font/google + `display: "optional"` + `preload: false`. CLS ~0 but woff2 still in critical path. |
| Performance-critical site (CWV is revenue, e.g. AdSense / SEO) | **Skip web fonts entirely.** Use OS Korean font chain in CSS. CLS ~0 AND no critical-path font fetches. |

Most data/content sites should pick option 2. The visual difference between Apple SD Gothic Neo / Pretendard / Malgun Gothic and Noto Sans KR is minor; the perf difference is huge.

## Why Korean web fonts hurt perf even with `display: "optional"`

`display: "optional"` correctly prevents the fallback→target swap (CLS goes to 0). But it does NOT prevent the font fetch.

The browser:
1. Parses CSS
2. Sees `@font-face { src: url("...woff2") }` with `font-display: optional`
3. Issues all the woff2 fetches anyway (they may be needed for "future" page loads)
4. Doesn't BLOCK rendering on them, but they're in the critical path of the network waterfall

For Korean Noto Sans KR, `next/font/google` generates ~14 separate woff2 chunks (one per Unicode subset range). On Slow 4G that's ~14 × 17KB = 250KB across ~14 sequential requests. Even unpreloaded, this delays LCP because:
- The CSS itself contains the @font-face declarations (CSS bloat)
- The font fetches saturate the connection slot
- Lighthouse "Render blocking requests" flags 1.5–2.0s wasted

## Option 2: drop Korean web fonts entirely

```ts
// app/layout.tsx — DON'T import next/font/google for Korean
// (no notoSansKr at all)
```

```css
/* globals.css */
@theme inline {
  --font-sans:
    -apple-system,                /* iOS / macOS — system Korean = Apple SD Gothic Neo */
    BlinkMacSystemFont,
    "Apple SD Gothic Neo",        /* explicit fallback */
    "Pretendard",                 /* respect user-installed Pretendard */
    "Malgun Gothic",              /* Windows */
    system-ui,
    sans-serif;
}

html, body {
  font-family: var(--font-sans);
  word-break: keep-all;           /* Korean shouldn't break mid-syllable */
}
```

Result:
- 0 KB of font assets fetched
- 0 KB of @font-face rules in CSS
- Korean text renders instantly with native OS font
- Most Korean users won't notice (they're used to these fonts in 카카오톡, 네이버, 인스타)

## When to keep `next/font/google` (Option 1)

If brand identity demands a specific weight or character (e.g. 마플샵 uses Pretendard heavily), use:

```ts
const pretendard = localFont({
  src: [{ path: "./fonts/Pretendard-Variable.woff2", weight: "100 900" }],
  variable: "--font-pretendard",
  display: "optional",
  preload: false,
});
```

Trade-off: still pays the woff2 fetch cost (one variable font ≈ 1–2 MB). Skipping preload + `display: optional` means slow-network users see fallback for entire session, which on returning visits is replaced by the cached font.

## Don't try

- ❌ Subsetting Korean Unicode (`unicode-range`) — modern 한글 has 11,172 syllables
- ❌ `display: "swap"` — fallback→target reflow CLS to 0.2+
- ❌ Preloading woff2 — 1–2 MB of preload tanks LCP on mobile
- ❌ Trusting `display: optional` alone for perf — it solves CLS, not LCP

## Verify

```bash
# After build, check for font fetches in critical path
ls .next/static/media/*.woff2 | wc -l
# Option 1 (Noto_Sans_KR): ~14 files, 250KB total
# Option 2 (OS fonts only): 0

# Lighthouse mobile
npx lighthouse https://your-site.com --form-factor=mobile --view
# Check "Network dependency tree" for woff2 in critical path
# Check "Render blocking requests" for CSS time including @font-face declarations
```

## More

- `reference.md` — Pretendard / Spoqa configs if you must use a web font, CSS fallback chain that looks native
- `scripts/check-fonts.sh` — audit `display`, `preload`, `subsets` for any Korean font import
  ```bash
  bash ~/.claude/skills/nextjs-cls-korean-fonts/scripts/check-fonts.sh /path/to/project
  ```
