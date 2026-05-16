/**
 * Click anchor similarity — 최소 동작 구현 예시.
 *
 * 핵심 함수:
 *   - cosineSimilarity(a, b): 두 벡터의 코사인 유사도 (-1~1, 보통 0~1)
 *   - rankBySimilarity(anchor, vecMap, exclude): anchor 기준 정렬
 *
 * 가중 유사도가 필요하면 weights 매개변수로 dim 별 강조 가능.
 */

export type FeatureVector = number[];

/** 코사인 유사도 — 두 벡터의 방향이 같을수록 1, 직각이면 0, 반대면 -1 */
export function cosineSimilarity(
  a: FeatureVector,
  b: FeatureVector,
  weights?: FeatureVector,
): number {
  const len = Math.min(a.length, b.length);
  let dot = 0;
  let aMag = 0;
  let bMag = 0;
  for (let i = 0; i < len; i++) {
    const w = weights?.[i] ?? 1;
    const ai = a[i] * w;
    const bi = b[i] * w;
    dot += ai * bi;
    aMag += ai * ai;
    bMag += bi * bi;
  }
  if (aMag === 0 || bMag === 0) return 0;
  return dot / (Math.sqrt(aMag) * Math.sqrt(bMag));
}

/** vector 평균 — 추천 모드에서 multi-pick centroid 계산 */
export function vectorMean(vectors: FeatureVector[]): FeatureVector {
  if (vectors.length === 0) return [];
  const dim = vectors[0].length;
  const sum = new Array<number>(dim).fill(0);
  for (const v of vectors) {
    for (let i = 0; i < dim; i++) sum[i] += v[i] ?? 0;
  }
  return sum.map((s) => s / vectors.length);
}

/** anchor 기준 모든 시설을 유사도 내림차순으로 정렬, exclude 제외 */
export function rankBySimilarity(
  anchor: FeatureVector,
  vecMap: Map<string, FeatureVector>,
  exclude: Set<string>,
  weights?: FeatureVector,
): Array<{ id: string; similarity: number }> {
  const ranked: Array<{ id: string; similarity: number }> = [];
  for (const [id, vec] of vecMap) {
    if (exclude.has(id)) continue;
    const similarity = cosineSimilarity(anchor, vec, weights);
    ranked.push({ id, similarity });
  }
  ranked.sort((a, b) => b.similarity - a.similarity);
  return ranked;
}

/**
 * autoWeights — 다중 픽 시 분산이 작은 dim 에 더 큰 가중치.
 *
 * 사용자가 3개 픽을 했는데 가격이 비슷하다면 → "가격은 중요한 기준". price dim 가중↑.
 * 위치가 흩어져 있다면 → 위치는 덜 중요. lat/lng dim 가중↓.
 *
 * 분산 역수를 가중치로 (정규화 없음, 단 0 으로 나누기 방지).
 */
export function autoWeights(picks: FeatureVector[]): FeatureVector {
  if (picks.length < 2) return [];
  const dim = picks[0].length;
  const mean = vectorMean(picks);
  const variance = new Array(dim).fill(0);
  for (const p of picks) {
    for (let i = 0; i < dim; i++) variance[i] += (p[i] - mean[i]) ** 2;
  }
  for (let i = 0; i < dim; i++) variance[i] /= picks.length;
  // 가중치 = 1 / (variance + ε), 정규화
  const eps = 0.001;
  const inv = variance.map((v) => 1 / (v + eps));
  const sum = inv.reduce((a, b) => a + b, 0);
  return inv.map((w) => (w / sum) * dim);
}

// === 사용 예시 ===
//
// // 1. 빌드 타임에 feature vector 사전 계산
// const vectors: Record<string, FeatureVector> = {
//   "1": [0.6, 37.5, 127.0, 0.2, 0.5, 0.3], // [price, lat, lng, subway, hospital, capacity]
//   "2": [0.7, 37.4, 127.1, 0.4, 0.6, 0.4],
//   ...
// };
//
// // 2. 사용자가 마커 클릭 → anchor 설정
// const anchorId = "1";
// const anchorVec = vectors[anchorId];
//
// // 3. 모든 시설을 anchor 기준으로 정렬
// const vecMap = new Map(Object.entries(vectors));
// const ranked = rankBySimilarity(anchorVec, vecMap, new Set([anchorId]));
//
// // 4. 결과: ranked[0] 가 가장 유사, ranked[N-1] 이 가장 다름
// for (const { id, similarity } of ranked.slice(0, 5)) {
//   console.log(`${id}: ${(similarity * 100).toFixed(1)}%`);
// }
