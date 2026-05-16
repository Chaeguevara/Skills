---
name: tier-grading-system
description: Build a multi-axis tier grading system (S/A/B/C/D) with absolute score thresholds, null-skip aggregation, and reason synthesis. Triggers when adding "best of"/recommendation/star/ranking systems where users want a single confident summary across multiple data axes.
---

# Multi-axis tier grading

Korean consumer apps love a single letter grade. Real estate, postpartum care, restaurants, nursing homes — users expect S/A/B/C tiers as a confidence shortcut.

**Bundled tool** (in this skill directory):
- `calibrate-thresholds.mjs` — feed it a JSON array of computed scores → prints percentile distribution + recommended thresholds + simulated grade counts. Usage: `node calibrate-thresholds.mjs scores.json`. Iterate until S ~10% / D ~10%.

## Recipe

### 1. Pick 3~5 axes — each measurable in 0~1

```ts
type Axes = {
  care: number | null;      // 케어 밀도
  meal: number | null;      // 영양·조리 인력 강도
  price: number | null;     // 가격 합리성 (vs 시군구 평균)
  longevity: number | null; // 영업 안정성
  capacity: number | null;  // 정원 적정성
};
```

null = 데이터 없음. **결측은 분모에서도 빠진다** — 정보 부족 패널티 X.

### 2. Score functions — clamped 0~1, monotonic

```ts
function clamp01(v: number): number {
  return Math.max(0, Math.min(1, v));
}

// 산모 N명당 간호 1명. N=2 perfect, N>=6 floor.
function scoreCare(care: number, capacity: number): number {
  if (care === 0 || capacity === 0) return 0;
  const ratio = capacity / care;
  return clamp01(1 - (ratio - 2) / 4);
}

// 평균 대비 가격. 0.7 = 1.0, 1.3 = 0.0.
function scorePrice(price: number, avg: number): number | null {
  if (avg <= 0) return null;
  const ratio = price / avg;
  return clamp01(1 - (ratio - 0.7) / 0.6);
}
```

각 함수는 **monotonic + clamped**. 외부 데이터 outlier 가 점수를 무한대로 만들지 않음.

### 3. Weighted average with null-skip

```ts
const WEIGHTS = { care: 25, meal: 20, price: 25, longevity: 15, capacity: 15 };

let totalWeight = 0;
let weighted = 0;
for (const key of Object.keys(WEIGHTS) as (keyof Axes)[]) {
  const v = axes[key];
  if (v === null) continue;       // skip — neither bonus nor penalty
  weighted += v * WEIGHTS[key];
  totalWeight += WEIGHTS[key];
}
if (totalWeight === 0) return { grade: "-", score: null, ... };
const score = (weighted / totalWeight) * 100;
```

### 4. Tune thresholds against actual distribution

```ts
function gradeFromScore(score: number): Grade {
  if (score >= 92) return "S";  // 상위 ~10%
  if (score >= 80) return "A";  // 상위 30%
  if (score >= 68) return "B";  // 중위 30%
  if (score >= 55) return "C";  // 하위 25%
  return "D";                    // 하위 ~10%
}
```

**Iterate against real data**:
```js
const counts = { S: 0, A: 0, B: 0, C: 0, D: 0 };
for (const center of centers) counts[grade(center)]++;
// Adjust thresholds until S = ~10%, D = ~10%
```

S 가 25% 이상이면 너무 후한 grade (S 가치 떨어짐). 5% 이하면 너무 짠 grade (대부분 B 이하).

### 5. Synthesize a reason line — strongest 1~2 axes

```ts
function buildReason(axes: Axes): string {
  const labels = [
    { key: "care",      label: "촘촘한 간호 케어",   v: axes.care },
    { key: "meal",      label: "탄탄한 영양·조리",  v: axes.meal },
    { key: "price",     label: "합리적 가격",       v: axes.price },
    { key: "longevity", label: "운영 안정성",       v: axes.longevity },
    { key: "capacity",  label: "소규모 케어",       v: axes.capacity },
  ].filter((l) => l.v !== null) as { label: string; v: number }[];

  const positives = labels.filter((l) => l.v >= 0.7).sort((a, b) => b.v - a.v);
  if (positives.length >= 2) return `${positives[0].label} + ${positives[1].label}`;
  if (positives.length === 1) return positives[0].label;
  const weak = labels.filter((l) => l.v <= 0.3).sort((a, b) => a.v - b.v);
  if (weak.length > 0) return `${weak[0].label} 보강 필요`;
  return "평균 수준";
}
```

사용자에게 grade 만 보여주면 "왜?" 라는 질문이 따라옴. **Reason 한 줄**이 신뢰감을 만든다.

### 6. Special states — out of business

영업/정상 외 (폐업/휴업) 시설은 "-" grade. 점수 계산 안 함:

```ts
if (statusCode !== "01") {
  return { grade: "-", score: null, reason: detailStatus ?? "영업 외" };
}
```

## Display contract

Component에는 `{ grade, score, reason }` 셋 다 노출. 사용자 신뢰의 빌딩 블록:

```tsx
<GradeBadge breakdown={breakdown} />
{/*
  S 92점 · 촘촘한 간호 케어 + 합리적 가격
  [산정 기준 →]   <- DevNote 링크
*/}
```

## Common mistakes

- **결측치 = 0점 처리** → 데이터 없는 시설이 항상 D 됨. 분모에서 빼야 공정.
- **임계 to-be-confirmed**: 분포 보고 fine-tune. 감으로 80/65/50 잡으면 S 가 50% 됨.
- **outlier 미처리**: 가격 0원 또는 인력 99명 같은 데이터 오류로 점수 폭주. 모든 score function 에 `clamp01`.
- **Reason 미포함**: grade 만 있으면 사용자가 의심. 한 줄 근거가 결정타.
- **transparency 부족**: DevNote 페이지에 가중치 + 임계 + 산정 로직 공개. 한국 사용자는 의심 많음.

## Real case — 테마지도 산후조리원

- 5축 × 25/20/25/15/15 가중
- S 92+ → 16% / A 80+ → 30% / B 68+ → 20% / C 55+ → 15% / D <55 → 17%
- DevNote 페이지(`/devnote#grading`)에서 임계와 로직 100% 공개
- 시설 상세 + 메인 카드 + 시도/시군구 area 페이지 TOP 3 모두 동일 grade 사용 → 일관된 신호
