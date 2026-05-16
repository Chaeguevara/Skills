#!/usr/bin/env node
/**
 * 등급 임계 calibration — 점수 분포를 보고 S/A/B/C/D 임계 추천.
 *
 * 사용:
 *   1) 모든 시설의 종합 점수를 JSON 으로 export (e.g. [{id, score}, ...])
 *   2) node calibrate-thresholds.mjs scores.json
 *
 * 출력:
 *   - 백분위 정리 (P10/P25/P50/P75/P90)
 *   - 추천 임계 (S 상위 10%, A 상위 35%, B 중위 30%, C 하위 25%, D 하위 10%)
 *   - 추천 임계 적용 시 분포 시뮬레이션
 *
 * 가이드:
 *   - S 분포 5~10% — 너무 후하면 등급 가치 떨어짐
 *   - D 분포 5~15% — 너무 적으면 변별력 없음
 *   - A+B 합계 50% 정도 — 평균적인 시설들
 */

import { readFileSync } from "node:fs";

const path = process.argv[2];
if (!path) {
  console.error("Usage: node calibrate-thresholds.mjs <scores.json>");
  console.error("  scores.json: [{id, score}, ...] or [score, ...]");
  process.exit(1);
}

const raw = JSON.parse(readFileSync(path, "utf8"));
const scores = raw
  .map((x) => (typeof x === "number" ? x : x.score))
  .filter((s) => typeof s === "number" && Number.isFinite(s))
  .sort((a, b) => a - b);

if (scores.length === 0) {
  console.error("no valid scores found");
  process.exit(1);
}

const pct = (p) => scores[Math.floor((p / 100) * (scores.length - 1))];

console.log(`\n=== Distribution (${scores.length} items) ===`);
console.log(`min: ${scores[0].toFixed(1)}`);
console.log(`p10: ${pct(10).toFixed(1)}`);
console.log(`p25: ${pct(25).toFixed(1)}`);
console.log(`p50: ${pct(50).toFixed(1)} (median)`);
console.log(`p75: ${pct(75).toFixed(1)}`);
console.log(`p90: ${pct(90).toFixed(1)}`);
console.log(`p95: ${pct(95).toFixed(1)}`);
console.log(`max: ${scores[scores.length - 1].toFixed(1)}`);

// 추천 임계 — 백분위 기반
const recommended = {
  S: Math.round(pct(90)), // 상위 10%
  A: Math.round(pct(65)), // 상위 35%
  B: Math.round(pct(35)), // 중위 30%
  C: Math.round(pct(10)), // 하위 25%
  // D: < C
};

console.log(`\n=== Recommended thresholds ===`);
console.log(`if (score >= ${recommended.S}) return "S";  // top 10%`);
console.log(`if (score >= ${recommended.A}) return "A";  // top 35%`);
console.log(`if (score >= ${recommended.B}) return "B";  // top 65%`);
console.log(`if (score >= ${recommended.C}) return "C";  // top 90%`);
console.log(`return "D";                       // bottom 10%`);

// 시뮬레이션
function gradeFromScore(score, t) {
  if (score >= t.S) return "S";
  if (score >= t.A) return "A";
  if (score >= t.B) return "B";
  if (score >= t.C) return "C";
  return "D";
}

const counts = { S: 0, A: 0, B: 0, C: 0, D: 0 };
for (const s of scores) counts[gradeFromScore(s, recommended)]++;

console.log(`\n=== Simulated distribution ===`);
const total = scores.length;
for (const g of ["S", "A", "B", "C", "D"]) {
  const n = counts[g];
  const pct = ((n / total) * 100).toFixed(1);
  const bar = "█".repeat(Math.round(parseFloat(pct) / 2));
  console.log(`${g}: ${String(n).padStart(4)} (${pct.padStart(5)}%) ${bar}`);
}

console.log(`\n=== Tips ===`);
if (counts.S / total > 0.15) {
  console.log("⚠ S 분포 > 15% — 너무 후함. S 임계 +3~5점 올리세요.");
}
if (counts.S / total < 0.03) {
  console.log("⚠ S 분포 < 3% — 너무 짠. S 임계 -3~5점 내리세요.");
}
if (counts.D / total > 0.20) {
  console.log("⚠ D 분포 > 20% — 너무 박함. D 임계 -5점 내리세요.");
}
console.log(
  `📊 절대 기준 권장 — 데이터 갱신 시 분포가 달라져도 등급 의미가 안정. percentile 기반은 데이터 변화 시 같은 시설 등급이 바뀌어 신뢰 ↓.`,
);
