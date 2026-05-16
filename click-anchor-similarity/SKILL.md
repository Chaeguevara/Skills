---
name: click-anchor-similarity
description: UX pattern for "click any item to compare with all others" without requiring multi-select. Compute single-vector cosine similarity to clicked anchor, sort list, show ≈XX% badges. Triggers when items have vectorizable features and users want to find "more like this".
---

# Click anchor similarity

A common need: user clicks a real estate listing / product / facility, and the rest of the list shows "how similar is each to this one?" — without forcing 3-pick comparison or saved favorites.

**Bundled tool** (in this skill directory):
- `example-implementation.ts` — minimal `cosineSimilarity` / `vectorMean` / `rankBySimilarity` / `autoWeights` functions. Drop into `lib/recommendation.ts` and import.

## When this beats classic recommendation

Classic "추천 받기 (3 개 픽 → centroid)" is great for shaping intent over multiple clicks. But adds friction for users who just want **"more like this one"**.

Anchor similarity = **zero-friction comparison**. One click, instant ranked list.

## Pattern

### 1. Pre-compute feature vectors at build time

```ts
// e.g. [priceNormalized, lat, lng, subwayDistance, hospitalDistance, capacity]
type FeatureVector = number[];
const vectors: Record<string, FeatureVector> = buildVectorsRecord(items);
```

Each feature normalized to similar scale (0~1 or z-score). Otherwise high-magnitude features dominate cosine.

### 2. On click, compute similarity to all others

```ts
const anchorSimilarity = useMemo(() => {
  if (!recLib || !selectedId) return null;
  const anchorVec = vectors[selectedId];
  if (!anchorVec) return null;
  const vecMap = new Map(Object.entries(vectors));
  const ranked = recLib.rankBySimilarity(
    anchorVec, vecMap, new Set([selectedId]), // exclude anchor itself
  );
  const simMap = new Map(ranked.map((r) => [r.id, r.similarity]));
  const order = new Map(ranked.map((r, i) => [r.id, i]));
  return { simMap, order };
}, [recLib, selectedId, vectors]);
```

Cheap — 500 items × 6 dims × 1 cosine = sub-millisecond.

### 3. Sort list by anchor order, anchor on top

```ts
const sorted = useMemo(() => {
  if (!anchorSimilarity) return defaultSort;
  return [...filtered].sort((a, b) => {
    if (a.id === selectedId) return -1;
    if (b.id === selectedId) return 1;
    return (anchorSimilarity.order.get(a.id) ?? 9999) - (anchorSimilarity.order.get(b.id) ?? 9999);
  });
}, [filtered, anchorSimilarity, selectedId]);
```

### 4. Show similarity on each card

```tsx
{simPct !== null && (
  <span className="rounded-full px-1.5 py-0.5 text-[10px] font-bold tabular-nums"
    style={{ backgroundColor: simPct >= 70 ? "#F4DCDD" : "#F2F1EC",
             color: simPct >= 70 ? "#8E3F4C" : "#5A5E68" }}>
    ≈ {simPct}%
  </span>
)}
{isAnchor && <Badge>기준</Badge>}
```

Color tiers:
- ≥70%: theme accent (very similar)
- 50~70%: neutral
- <50%: muted (visible but de-emphasized)

## Why it feels right

- **Zero ceremony** — click and see. No "step 1 / step 2 / step 3".
- **Self-evident comparison** — "이 시설과 비슷한 다른 시설" 직관적
- **Stays out of the way** — clicking a different one re-anchors. Clicking outside resets.
- **Composes with filters** — anchor sort applies AFTER filters, so anchor + 시군구 + 가격대 모두 동시 적용

## Coexistence with other modes

If your app also has multi-pick recommendation mode (가성비 + 위치 + ... 3개 비교), anchor mode is the **default off**, multi-pick is **opt-in via "추천 받기" button**:

```tsx
const recommendComplete = recommendMode && picks.length >= 3 && recLib;

const sorted = useMemo(() => {
  if (recommendComplete) return recommendedItems;     // multi-pick wins
  if (anchorSimilarity) return anchorSortedItems;     // anchor wins over default
  if (curationId !== "all") return curatedItems;      // curation preset
  return defaultSort;
}, [...]);
```

Priority: explicit recommendation > implicit anchor > curation > sort. Each layer transparent and revertable.

## Real case — 테마지도 산후조리원

Anchor similarity over 6 features (price, lat, lng, subway m, obgyn m, hospital m). Click a center → sidebar list re-sorts by similarity, ≈XX% badge on each card. No "추천 모드 진입" friction. Adopted as main UX after testing showed multi-pick was used by < 5% of sessions while anchor compares felt natural to nearly all.

## Anti-patterns

- ❌ **Fetching upstream API per click** — pre-compute vectors at build time, similarity is in-memory.
- ❌ **Expensive feature engineering on click** — keep vectors small (5~10 dims), keep distance metric simple.
- ❌ **Showing percentages without "기준" label on anchor** — confusing without reference.
- ❌ **Re-computing on every render** — wrap in `useMemo` keyed on selectedId + vectors.
- ❌ **Forcing sort to override user choice** — let user pick "이름순" / "가격순" via dropdown; anchor is just one mode.
