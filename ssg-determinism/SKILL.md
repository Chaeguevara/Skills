---
name: ssg-determinism
description: Pre-compute data at build time without breaking deterministic builds. Triggers when running clustering, sampling, or any randomized algorithm in a Next.js SSG / Astro build / static generation step that should produce the same output every build.
disable-model-invocation: false
---

# Deterministic SSG pre-computation

## The trap

Math.random() in code that runs during `next build` (server components, generateStaticParams loaders, scripts) produces different output each build. For:

- K-means / K-medoids clustering → different cluster IDs
- Sampling → different "top N"
- Hash-based assignment → different bucket per build

This breaks **incremental redeploys, cache hits, and CDN edge cache**. Worse: users see a different "recommended" / "clustered" view per deploy with no real underlying data change.

## Symptoms

- "Recommendation pages keep changing between deploys"
- "Cluster assignments shuffle on every CI run"
- Diffs in committed `data/*.json` even when input is identical

## Fix patterns

### K-means: max-min-distance init (deterministic, ≈K-means++ quality)

```ts
function initialCenters(points: Vec[], k: number): Vec[] {
  const centers: Vec[] = [points[0]]; // deterministic seed
  while (centers.length < k) {
    let bestIdx = -1;
    let bestDist = -1;
    for (let i = 0; i < points.length; i++) {
      const minDist = Math.min(
        ...centers.map((c) => distance(points[i], c)),
      );
      if (minDist > bestDist) {
        bestDist = minDist;
        bestIdx = i;
      }
    }
    centers.push(points[bestIdx]);
  }
  return centers;
}
```

The first center is `points[0]` (stable: input is sorted by ID). Each subsequent center maximizes minimum distance from picked centers — same input → same output.

### Sampling: take ordered, not random

```ts
// ❌ const sample = arr.sort(() => Math.random() - 0.5).slice(0, n);
// ✅
const sample = arr.slice(0, n);  // input must be deterministically ordered
```

Sort by a stable key (e.g. id, score) before slicing.

### Seeded RNG (when you really need randomness)

```ts
// mulberry32 — small, deterministic
function mulberry32(seed: number) {
  return function () {
    seed |= 0;
    seed = (seed + 0x6D2B79F5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rng = mulberry32(42);  // fixed seed
```

## Verify

After running ingest / build twice, the diff should be empty:

```bash
npm run build && cp -r data/clustered data/clustered-1
npm run build && diff -r data/clustered data/clustered-1
# expect no output
```

Or in CI: assert `git diff --exit-code data/` after the build step.
