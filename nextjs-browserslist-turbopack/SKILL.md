---
name: nextjs-browserslist-turbopack
description: Modern-target browser compilation in Next.js 16+ with Turbopack. Triggers when Lighthouse "Legacy JavaScript" still flags Array.prototype.at / flat / flatMap / Object.fromEntries / Object.hasOwn polyfills despite setting browserslist, or when a Next.js bundle ships ~14KB of unnecessary polyfills.
disable-model-invocation: false
---

# Next.js 16 + Turbopack + browserslist

## The trap

Putting `browserslist` in `package.json` does NOT take effect for Next.js 16 + Turbopack production builds. SWC's transform pipeline reads from a different resolution path than Webpack used to.

Symptom: Lighthouse "Legacy JavaScript" insight keeps flagging the same polyfills (~14 KB):
- `Array.prototype.at`
- `Array.prototype.flat`
- `Array.prototype.flatMap`
- `Object.fromEntries`
- `Object.hasOwn`
- `String.prototype.trimStart`
- `String.prototype.trimEnd`

These are all Baseline-supported (Chrome 88+, Safari 14+) — not needed for any modern target.

## Fix: use a `.browserslistrc` file

```
# .browserslistrc — at repo root
Chrome >= 88
Edge >= 88
Firefox >= 78
Safari >= 14
iOS >= 14
not dead
```

A standalone file is read reliably by SWC during Turbopack builds. The `package.json` field gets ignored in some Next 16 build paths.

## Do NOT bump targets too aggressively

Tempting to set `Chrome >= 100, Safari >= 16` etc. Don't — Korean / Japanese mobile users still have older Safari. The targets above (Chrome 88 / Safari 14, mid-2020) cover ~98% of real users while dropping the major polyfills.

## Verify

```bash
# After build, check the "framework" or "main" chunk for polyfills
grep -lE 'Array\.prototype\.at|Object\.fromEntries|Object\.hasOwn' .next/static/chunks/*.js | head -5
# Expect: empty — no chunk contains those polyfill markers

# Lighthouse: "Legacy JavaScript" insight should not flag them
```

If a chunk still has them after the change, also check `next.config.ts` — if you have a custom `webpack` config that overrides target, that wins over browserslist.

## Related: don't transpile node_modules

Some projects ship polyfills because a dependency is pre-transpiled to ES5. Look for:
- A package that publishes `dist/` already transpiled (unusual but it happens — e.g. older charting libs)
- A `swcLoader` or babel config that explicitly transpiles node_modules

By default Next does not transpile dependencies. If a dep is the source of polyfills, contact the maintainer or import a leaner alt.

## More

- `scripts/check-polyfills.sh` — grep built chunks for legacy method polyfills, report which chunk has them
  ```bash
  bash ~/.claude/skills/nextjs-browserslist-turbopack/scripts/check-polyfills.sh /path/to/project
  ```
