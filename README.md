# Skills

Claude Code skills for persistent knowledge and automation across every session.

## Reference / domain knowledge

### `geometric-folding`
Reference knowledge base for mathematical and computational origami. Loaded automatically when any session touches folding theory.

Covers: Maekawa's theorem (`|M−V|=2`), Kawasaki's theorem (alternating angles), local foldability conditions, local foldability graphs (LFG), degree-4 vertices, layer ordering, global flat-foldability (NP-hardness), tree method, box pleating, and rigid origami.

Files: `SKILL.md`, `theorems-deep.md`

---

### `obsidian-knowledge`
Captures knowledge into the Obsidian PARA vault as a properly formatted markdown note with wiki-links to related existing notes.

Triggers on: "save this", "add this to my vault", "create a note for this", "take notes on", or pasted content to preserve.

Files: `SKILL.md`, `frontmatter-patterns.md`, `vault-index.md`

---

### `obsidian-daily`
Creates today's daily note in the Obsidian PARA vault (`00.Inbox/YYYY-MM-DD.md`). Reports the path if the note already exists; otherwise creates it from a lean template.

Files: `SKILL.md`

## Web / Next.js gotchas (general)

These capture footguns I've stepped on more than once. Each is a self-contained `SKILL.md` with reproducer + fix.

### `nextjs-adsense-script`
Add Google AdSense to a Next.js App Router site without breaking the `data-nscript` validator. Use raw `<script>` JSX or lazy DOM injection — never `next/script` directly.

### `nextjs-search-params-ssg`
Read `?foo=bar` query params in a fully static page without breaking SSG. `useSearchParams()` requires a Suspense boundary; use `window.location.search` in `useEffect` for cosmetic flags.

### `nextjs-cls-korean-fonts`
Fix Cumulative Layout Shift caused by Korean web fonts loaded via `next/font/google`. `display: "optional"` + `preload: false` eliminates the swap-driven reflow.

### `ssg-determinism`
Pre-compute clusters / samples / rankings at build time without breaking deterministic builds. Replace `Math.random` with seeded RNG or max-min-distance init.

### `rsc-client-prop-shape`
Decide what shape of data to send from a Next.js Server Component to a Client Component. Project to compact form before passing — large props inflate the page HTML and hurt LCP.

### `nextjs-og-image-metadata`
Avoid the `generateImageMetadata` footgun in dynamic OG image routes. If misused, every page in `[id]/opengraph-image.tsx` gets `<meta og:image>` tags for ALL siblings — RSC payload bloats 5–10×. Includes a scanner.

### `nextjs-browserslist-turbopack`
Force modern-target browser compilation in Next 16 + Turbopack. `package.json` `browserslist` is silently ignored; use `.browserslistrc` to drop ~14KB of legacy method polyfills. Includes a polyfill scanner.

### `nextjs-preconnect-strategy`
Decide where to put `<link rel="preconnect">` in App Router — root layout vs per-page. Avoids "Unused preconnect" / ">4 preconnects" Lighthouse warnings. Covers the silent-killer crossorigin mismatch (preconnect's `crossOrigin` must match the actual fetch's mode) + preconnect vs dns-prefetch trade-off.

### `nextjs-conditional-feature-bundling`
Chunk-split conditional features (`?beta=1`, modals, admin panels) so they only download when triggered. Components via `next/dynamic`, libraries via `import()` inside `useEffect`. Includes a scanner for static-import + conditional-render candidates.

### `bulk-data-via-script-not-tokens`
대량 데이터(공공 API, 엑셀, CSV, 페이지네이션 응답)를 토큰으로 처리하지 않고 데이터 구조를 이해한 뒤 스크립트로 옮기는 패턴. probe → script → metrics-only report. 한글 정규화, 페이지네이션, 매칭 폴백 체인 포함.

---

## Structure

Each skill is a directory containing `SKILL.md` (frontmatter + body). Some skills also bundle reference scripts/templates that the body links to:

```
skills/
├── data-go-kr-api-quirks/
│   ├── SKILL.md
│   ├── probe-endpoint.sh        # bash probe for /info /list /v1 path discovery
│   └── ingest-skeleton.mts      # reusable TS ingest with pagination + matching
├── tier-grading-system/
│   ├── SKILL.md
│   └── calibrate-thresholds.mjs # feed scores → recommend S/A/B/C/D thresholds
├── click-anchor-similarity/
│   ├── SKILL.md
│   └── example-implementation.ts  # cosine similarity + autoWeights + rank
├── nextjs-static-route-bundle/
│   ├── SKILL.md
│   └── route-template.ts        # copy-paste route handler + client fetch
└── ...                          # other skills (markdown only when self-contained)
```

When a skill has a "Bundled tool" callout near the top of its SKILL.md, that means it ships with reusable scripts. Single-md skills are self-contained patterns where the inline code snippet is enough.
