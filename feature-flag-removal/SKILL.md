---
name: feature-flag-removal
description: Cleanly remove a "?beta=1" / feature flag gate when promoting a feature to GA. Triggers when an isBeta / featureEnabled flag has been gating UI for a while and the user says "promote this to main" / "ship it" / "remove the gate".
---

# Promoting a beta feature

## When this kicks in

Flag like `isBeta` or `featureEnabled` has been protecting risky UI from regular users. User says ship it. The flag's tendrils are everywhere.

## The mechanical step

1. **Search every reference**:
   ```bash
   grep -rn "isBeta" src/
   ```

2. **In ESLint deps arrays of useMemo/useCallback/useEffect** — remove `isBeta` from deps and any guards that reference it:
   ```ts
   // before
   }, [filtered, sort, isBeta, curationId]);
   // after
   }, [filtered, sort, curationId]);
   ```

3. **In conditionals** — reduce to only the meaningful gate:
   ```ts
   // before
   if (isBeta && curationId !== "all") return curated;
   // after
   if (curationId !== "all") return curated;
   ```

4. **In JSX** — unwrap:
   ```tsx
   // before
   {isBeta && <CurationTabs ... />}
   // after
   <CurationTabs ... />
   ```

5. **In useEffect data loading** — change trigger from beta entry to a more sensible one:
   ```ts
   // before — load lib only when user enters beta
   useEffect(() => { if (!isBeta || lib) return; import(...).then(setLib); }, [isBeta, lib]);
   // after — load lib when bundle is ready (it's now needed always)
   useEffect(() => { if (!bundle || lib) return; import(...).then(setLib); }, [bundle, lib]);
   ```

6. **Drop the state entirely** if it has no other use:
   ```ts
   const [isBeta, setIsBeta] = useState(false);
   useEffect(() => {
     const params = new URLSearchParams(window.location.search);
     if (params.get("beta") === "1") setIsBeta(true);
   }, []);
   ```
   If nothing reads `isBeta` after migration, delete the whole block.

## What to keep behind a flag

Not everything must be ungated. Some features are intentionally power-user:

- Map clusterer (`?cluster=1`) — useful when zoomed out at country level, but obscures marker labels
- Admin / debug overlays
- Performance toggles (e.g. `?disable-analytics=1`)

Keep these behind a query-param flag. Don't expose in main UI.

```ts
const [clusterEnabled, setClusterEnabled] = useState(false);
useEffect(() => {
  const params = new URLSearchParams(window.location.search);
  if (params.get("cluster") === "1") setClusterEnabled(true);
}, []);
```

## Verify after removal

- `grep -rn "isBeta" src/` returns nothing
- `npm run lint` passes (deps array warnings catch missed migrations)
- `npm run build` passes
- Visual regression check on the promoted feature — make sure default state looks right

## Real case — 테마지도 추천 모드 승격

`isBeta` was gating: BETA badge bar, "추천 받기" button, RecommendBar, CurationTabs, recLib loading, marker context labels for picks/recommends, cluster.

Promotion split into two:
- **Main**: 추천 받기 button, CurationTabs, RecommendBar, recLib (always loaded after bundle)
- **Power user (?cluster=1)**: clustering only

Total references removed: 14 across 1 file. Net: -14 isBeta references, +1 clusterEnabled query gate.

Once-protected features are now the default UX. Beta badge bar gone (no longer signals tentative status).

## Don't forget

- Remove "BETA" label, amber tint, "이 기능은 실험 중" 카피
- Update docs / DevNote to reflect new default state
- Update screenshots in marketing pages if any
- Update analytics labels — old "beta_curation_click" → "curation_click"
