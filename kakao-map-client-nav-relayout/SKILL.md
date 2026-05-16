---
name: kakao-map-client-nav-relayout
description: Kakao Map SDK fails to render after Next.js client-side navigation back to a page (blank map). Two causes — stale container children + flexbox dimension delay. Fix with container cleanup before init + ResizeObserver-driven relayout.
---

# Kakao Map blank after client navigation

## Symptom

User flow:
1. Land on `/map` — map renders fine
2. Navigate to `/map/place/12` (detail)
3. Click breadcrumb back to `/map`
4. **Map area is blank** — no tiles, no markers

Worse, Lighthouse / direct URL load works fine. Only client-nav reproduces.

## Two compounding causes

### Cause 1: Stale container children

When `KakaoMap` unmounts and remounts (Strict Mode in dev, or genuine remount via Next router), the previous `kakao.maps.Map` instance may have left DOM nodes inside `containerRef.current`. New Map instance gets created on top, but tiles can't compute layout against the leftover DOM.

### Cause 2: Flexbox dimension delay

Next.js client navigation transitions through layouts in microtasks. A `<div className="flex-1 min-h-0">` that contains the map may resolve to **0×0** for a frame or two after mount. Kakao SDK initializes against 0×0 → tiles don't load. The first `relayout()` fires too early to recover.

## Fix

```tsx
useEffect(() => {
  let cancelled = false;
  loadKakaoMaps()
    .then((kakao) => {
      if (cancelled || !containerRef.current) return;

      // Cause 1: clear stale children before new Map
      const container = containerRef.current;
      while (container.firstChild) container.removeChild(container.firstChild);

      const instance = new kakao.maps.Map(container, {
        center: new kakao.maps.LatLng(lat, lng),
        level,
      });
      setMap(instance);

      // Cause 2: relayout on every resize until container settles
      if (typeof ResizeObserver !== "undefined") {
        const ro = new ResizeObserver(() => instance.relayout());
        ro.observe(container);
        // Tag observer so we don't double-attach
        (instance as kakao.maps.Map & { __ro?: ResizeObserver }).__ro = ro;
      }
    })
    .catch((err: Error) => {
      if (!cancelled) setError(err.message);
    });
  return () => { cancelled = true; };
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, []);
```

`ResizeObserver` will fire when:
- Initial 0×0 → real dimensions transition
- Window resize
- Parent layout reshuffles after navigation

Each fire calls `instance.relayout()` — Kakao re-fetches tiles for new size. Cheap and idempotent.

## What doesn't work

- `requestAnimationFrame(() => relayout())` — runs once, may still be 0×0
- `setTimeout(relayout, 100)` — guess-and-pray
- `key={pathname}` on map component — forces remount but doesn't fix the underlying container issue
- Calling `relayout()` only when `bounds` changes — bounds may not change on nav back

## Why this is hard to debug

- `console.log(containerRef.current.getBoundingClientRect())` shows correct size **by the time you check** (event loop later)
- Map instance exists, listeners exist, no errors thrown
- Tile network requests don't fire (no `t1.daumcdn.net` in Network tab) — that's the giveaway
- Affects only client navigation back to the page, not direct URL load — easy to miss in testing

## Generalization

Same pattern applies to other map SDKs (Naver, MapLibre, Mapbox, Leaflet) — any map that initializes against container dimensions. ResizeObserver-driven relayout is the universal fix.

## Real case

`src/components/map/KakaoMap.tsx` in 테마지도. Reproduced going `/place/12` → breadcrumb → `/parenting/postpartum-care`. After fix, map renders consistently across all navigation paths.
