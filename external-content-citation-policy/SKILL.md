---
name: external-content-citation-policy
description: When the user shares an external URL as a data source ("이 사이트 정보로 만들어", "여기있는 데이터 빼올수 있나", "참조해서 만들어"), do not copy text verbatim. Use only neutral facts (addresses, dates, hours, names) and require an officialUrl link to the source page on every derived record. Applies to government portals, religious institutions, business directories, archives, etc.
disable-model-invocation: false
---

# 외부 출처 콘텐츠 인용 정책

한국 중·소형 기관 사이트 (정부 포털, 종교기관, 협회) 의 텍스트는 저작권 명시가 약해도 보호받음. 직접 복사 = 법적 노출 + 저질 파생 콘텐츠. 사용자가 명시하기도 함: **"데이터를 훔칠수는 없으니, 출처와 링크를 그쪽으로 걸어서"**.

## 트리거

- 사용자가 URL 공유 + **"이 정보로 만들어"** / **"참조해서"** / **"여기있는 데이터로"** / **"이거 보고 만들어"**
- 도메인이 외부 1차 출처에 의존하는 경우 (예: martyrs.or.kr, aurum.re.kr, data.go.kr)

## 6가지 정책

1. **사실만 사용** — 주소·날짜·운영시간·가격·공식 명칭. **서술 prose, 마케팅 카피, 슬로건 복사 금지**
2. **자체 작성** — 2-4 문장 요약을 자기 표현으로. 직접 인용해야 한다면 따옴표 + 명시
3. **`officialUrl: string` 필드 필수** — 데이터 모델에 non-optional 로. 모든 record 가 출처 페이지 가리킴
4. **UI 에 노출** — 상세 페이지에 "More info / Verify before visit → [official source]" 버튼 prominent
5. **이미지 직접 사용 금지** — Wikimedia Commons CC 라이선스 + 크레딧만. hotlink X
6. **변동 정보 (시간·가격) → 외부 링크만** — 데이터에 박지 마라. "Verify before visit" 명시

## Spec 에 박을 것

새 도메인 spec 작성 시 invariant 로:

```ts
type X = {
  // ...
  officialUrl: string;  // non-optional
  // 변동 정보는 옵션이거나 short hint 만
  hoursHint?: string;   // "Sundays 9 AM" 정도, 정확한 시간은 officialUrl 참조
};
```

## 좋은 사례 (theme-maps)

- `architecture` 도메인: `Building.wikipediaUrl?` (출처) + 모든 description 자체 작성
- `pilgrimage` 도메인 (spec only): `HolySite.officialUrl: string` non-optional, 미사 시간은 짧은 hint + 정확한 건 외부 링크

## 나쁜 사례 (안 한 일)

- aurum.re.kr 의 building DB 를 통째로 스크랩 (시도 안 함 — 수동 큐레이션 v1.5 유지)
- namu.wiki 본문을 한국어로 그대로 가져오기 (시도 안 함)

## 추가 룰

- 사이트가 robots.txt 또는 ToS 로 스크래핑 금지하면 더 강한 신호. 빌드타임 fetch 도 금지
- 정부 출처 (data.go.kr 등) 는 라이선스 명시 — 보통 KOGL 1형. 사용 가능하지만 출처 라이선스 표기
- 모바일 앱 (martyrs.or.kr 의 "Seoul Pilgrimage Route" 등) 데이터 추출 시도 금지
