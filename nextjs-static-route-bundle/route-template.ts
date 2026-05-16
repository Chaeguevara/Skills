/**
 * Next.js App Router 정적 JSON 라우트 핸들러 템플릿.
 *
 * 위치: src/app/data/<name>.json/route.ts
 *
 * 사용:
 *   1) 이 파일을 src/app/data/foo-bundle.json/route.ts 로 복사
 *   2) loadFooData / 가공 로직 / 응답 schema 교체
 *   3) 클라이언트에서 fetch("/data/foo-bundle.json", { cache: "force-cache" })
 *
 * 빌드 타임에 한 번만 GET 호출 → JSON 파일 정적 생성 → CDN 캐시.
 * 런타임 외부 API 호출 0 회 + 페이지 HTML 슬림.
 */
import { NextResponse } from "next/server";
// import { loadFooData } from "@/lib/foo";

// 정적 빌드 강제 — 빌드 타임에 한 번만 실행, 결과 JSON 을 정적 파일로 보존.
export const dynamic = "force-static";

// revalidate=false → 빌드 한번만, 런타임 재검증 X (배포 후 변동 없음).
export const revalidate = false;

export function GET() {
  // 1) 원본 데이터 로드 (예: JSON / DB / fs)
  // const items = loadFooData();

  // 2) 빌드 타임에 무거운 가공 — 클라이언트 부담 0
  // - 평균/통계/벡터/등급 등 모두 여기서.
  // - 하나의 JSON 응답 = 클라이언트 한 번 fetch 면 끝.

  // 3) 응답 — Type-safe 하게 정의
  type Bundle = {
    items: Array<{ id: string; name: string }>;
    derived: { avg: number; total: number };
  };

  const bundle: Bundle = {
    items: [],
    derived: { avg: 0, total: 0 },
  };

  return NextResponse.json(bundle);
}

/**
 * 클라이언트 측 fetch 패턴:
 *
 * ```tsx
 * "use client";
 * import { useState, useEffect } from "react";
 *
 * type Bundle = {
 *   items: Array<{ id: string; name: string }>;
 *   derived: { avg: number; total: number };
 * };
 *
 * export default function FooView() {
 *   const [bundle, setBundle] = useState<Bundle | null>(null);
 *   const [error, setError] = useState<string | null>(null);
 *   const [attempt, setAttempt] = useState(0);
 *
 *   useEffect(() => {
 *     let aborted = false;
 *     setError(null);
 *     fetch("/data/foo-bundle.json", { cache: "force-cache" })
 *       .then((r) => {
 *         if (!r.ok) throw new Error(`HTTP ${r.status}`);
 *         return r.json();
 *       })
 *       .then((data: Bundle) => { if (!aborted) setBundle(data); })
 *       .catch((err: Error) => { if (!aborted) setError(err.message); });
 *     return () => { aborted = true; };
 *   }, [attempt]);
 *
 *   if (!bundle && !error) return <div>로딩 중…</div>;
 *   if (error) return (
 *     <div>
 *       <p>불러오기 실패: {error}</p>
 *       <button onClick={() => setAttempt((n) => n + 1)}>다시 시도</button>
 *     </div>
 *   );
 *   return <RealUI bundle={bundle!} />;
 * }
 * ```
 *
 * 핵심:
 *   - cache: "force-cache" — 브라우저 메모이즈
 *   - 명시적 loading + error 상태 — "0 results" 플래시 방지
 *   - attempt state 로 다시 시도 트리거
 *   - aborted ref 로 unmount 후 setState 안 함
 */
