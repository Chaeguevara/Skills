# SSG determinism — extended reference

## Drop-in: deterministic K-means with max-min-distance init

```ts
// src/lib/clustering.ts
export type Vec = number[];

const MAX_ITERATIONS = 50;
const CONVERGENCE_THRESHOLD = 1e-6;

function distance(a: Vec, b: Vec): number {
  let s = 0;
  for (let i = 0; i < a.length; i++) {
    const d = a[i] - b[i];
    s += d * d;
  }
  return Math.sqrt(s);
}

function mean(points: Vec[]): Vec {
  const dim = points[0].length;
  const out = new Array(dim).fill(0);
  for (const p of points) for (let i = 0; i < dim; i++) out[i] += p[i];
  for (let i = 0; i < dim; i++) out[i] /= points.length;
  return out;
}

/**
 * Pick K initial centers using max-min-distance heuristic.
 * Stable: same input (assuming caller passed sorted points) → same output.
 */
function pickInitialCenters(points: Vec[], k: number): Vec[] {
  if (points.length === 0 || k === 0) return [];
  const centers: Vec[] = [points[0].slice()]; // deterministic seed
  while (centers.length < k && centers.length < points.length) {
    let bestIdx = -1;
    let bestDist = -Infinity;
    for (let i = 0; i < points.length; i++) {
      let minD = Infinity;
      for (const c of centers) {
        const d = distance(points[i], c);
        if (d < minD) minD = d;
      }
      if (minD > bestDist) {
        bestDist = minD;
        bestIdx = i;
      }
    }
    if (bestIdx === -1) break;
    centers.push(points[bestIdx].slice());
  }
  return centers;
}

export type KMeansResult = {
  centers: Vec[];
  assignments: number[]; // assignments[i] = cluster index for points[i]
  iterations: number;
};

export function kmeans(
  points: Vec[],
  k: number,
  opts: { maxIter?: number; epsilon?: number } = {},
): KMeansResult {
  const maxIter = opts.maxIter ?? MAX_ITERATIONS;
  const eps = opts.epsilon ?? CONVERGENCE_THRESHOLD;
  if (points.length === 0) return { centers: [], assignments: [], iterations: 0 };
  if (k <= 1) {
    return { centers: [mean(points)], assignments: new Array(points.length).fill(0), iterations: 0 };
  }

  let centers = pickInitialCenters(points, k);
  let assignments = new Array(points.length).fill(0);
  let iter = 0;

  for (; iter < maxIter; iter++) {
    // Assign each point to nearest center
    let changed = false;
    for (let i = 0; i < points.length; i++) {
      let bestIdx = 0;
      let bestDist = Infinity;
      for (let c = 0; c < centers.length; c++) {
        const d = distance(points[i], centers[c]);
        if (d < bestDist) { bestDist = d; bestIdx = c; }
      }
      if (assignments[i] !== bestIdx) { assignments[i] = bestIdx; changed = true; }
    }

    // Recompute centers
    const newCenters: Vec[] = [];
    let totalShift = 0;
    for (let c = 0; c < centers.length; c++) {
      const members = points.filter((_, i) => assignments[i] === c);
      if (members.length === 0) {
        newCenters.push(centers[c].slice()); // keep stable
        continue;
      }
      const m = mean(members);
      totalShift += distance(centers[c], m);
      newCenters.push(m);
    }
    centers = newCenters;
    if (!changed || totalShift < eps) { iter++; break; }
  }

  return { centers, assignments, iterations: iter };
}
```

## Drop-in: seeded RNG (mulberry32)

When you genuinely need pseudorandomness in a build step:

```ts
// src/lib/seeded-rng.ts

/** mulberry32 — small, fast, deterministic. Period 2^32. */
export function makeRng(seed: number): () => number {
  let s = seed | 0;
  return function () {
    s = (s + 0x6D2B79F5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Fisher-Yates shuffle with a seeded RNG. */
export function shuffle<T>(arr: T[], rng: () => number): T[] {
  const out = arr.slice();
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

/** Pick N items deterministically from an array. */
export function sample<T>(arr: T[], n: number, seed: number): T[] {
  const rng = makeRng(seed);
  return shuffle(arr, rng).slice(0, n);
}
```

Pass a fixed seed (e.g. derived from the dataset version, NOT `Date.now()` or process pid).

## Sources of nondeterminism that aren't `Math.random`

| Source | Why it's nondeterministic | Fix |
|---|---|---|
| `Date.now()` / `new Date()` | Build start time differs per build | Use a fixed timestamp from data, or read from package.json version |
| `Object.entries(map)` from a non-Map | Object key order is mostly stable but not guaranteed across engines | Sort keys explicitly: `Object.keys(o).sort()` |
| `Set` / `Map` iteration | Insertion order — fine if construction is deterministic | Construct from sorted input |
| `Array.sort` w/o comparator | Stable in V8/modern but spec required stability only since ES2019 | Always pass an explicit comparator |
| Parallel workers / Promise.all results | Resolution order may differ | Sort by stable key after collecting |
| File system iteration (`readdirSync`) | OS-dependent ordering | Sort the result |
| Network calls (geocoding, AI) | Service may return slightly different responses | Cache results, commit cache |

## Determinism check workflow

1. Run the full pipeline twice on a clean checkout
2. `diff -r` the output
3. If any diff → find the source

```bash
# In CI (run after the build/ingest step)
git diff --exit-code data/
```

If `data/` has changes that weren't committed, the build is nondeterministic.
