---
name: bulk-data-via-script-not-tokens
description: 대량 데이터(공공 API, 엑셀, CSV, 페이지네이션 응답 등)는 토큰으로 처리하지 말고 데이터 구조를 이해한 뒤 스크립트로 처리. 토큰 낭비 + 정확도 저하 + 느린 피드백 루프를 피한다.
---

# Bulk data → script, not tokens

## When this kicks in

- 공공 API (data.go.kr, LOCALDATA, KOSIS, 행정안전부) 처럼 **수백~수만 row** 짜리 응답
- 엑셀/CSV 다년치 ingest (`data/raw/*.xlsx`)
- 페이지네이션 (한 페이지 100row × 다수 페이지)
- 여러 파일에 흩어진 데이터를 **매칭/조인**해야 하는 작업

## The rule

**토큰으로 데이터를 흘리지 말 것.** 대량 응답을 본문에 받아서 LLM 이 한 row 씩 파싱·정규화·매칭하는 흐름은:

- 토큰을 빠르게 소진 (한 응답이 컨텍스트 절반)
- 한글/숫자 정규화에서 비결정적인 실수
- 다음 페이지 반복 시 같은 작업 또 처리
- 사용자가 결과를 검증할 수 없음 (스크립트 = 재실행 가능, 채팅 = 재현 불가)

대신:

1. **샘플 1~2 row 만 토큰으로 받기** — 스키마 / 필드 의미 파악용
2. **스크립트(.mts) 작성** — 페치 + 정규화 + 조인 + 저장
3. **스크립트 실행** — 결과는 JSON 으로 저장
4. **로그 줄 수** 만 토큰으로 (예: `matched=391/473 unmatched=82`)

## Concrete shape

### Probe phase — endpoint/schema 파악
```bash
# 미니멀 호출로 첫 번째 record 만 토큰에 가져와서 필드 이해
curl -sS "${ENDPOINT}?serviceKey=${KEY}&numOfRows=1" \
  | node -e 'JSON.parse(...).response.body.items.item[0]'
# → 필드명, 키 후보(전화번호/주소), 페이지네이션 동작 파악
```

### Process phase — 스크립트로 옮김
```typescript
// scripts/ingest-foo.mts
async function fetchAll(): Promise<Item[]> {
  const PER_PAGE = 100; // ⚠️ 서버가 numOfRows 를 캡할 수 있음 — probe 단계에서 확인
  const all: Item[] = [];
  let total = 0;
  for (let page = 1; page <= 30; page++) {
    const r = await fetch(`${ENDPOINT}?...&pageNo=${page}&numOfRows=${PER_PAGE}`);
    const j = await r.json();
    const items = j.response?.body?.items?.item ?? [];
    total = j.response?.body?.totalCount ?? total;
    all.push(...items);
    if (items.length === 0 || all.length >= total) break;
  }
  return all;
}

// 매칭은 인덱스 + 폴백 체인으로 명시적으로
const byPhone = new Map<string, Center>();
const byAddrName = new Map<string, Center>();
// ...
```

### Report phase — 토큰엔 메트릭만
```
matched: phone=266 addrName=37 nameDistrict=112 unmatched=599
coverage: 391/473 — active=381 closed=26
```

## Anti-patterns

### ❌ "응답 다 받아서 LLM 이 row 별로 매칭"
- 1014 row × 30+ 필드 = 컨텍스트 폭주
- 대신 스크립트가 매칭 후 `byId` 만 저장

### ❌ "한 page 받고 LLM 이 다음 page 결정"
- 페이지네이션은 결정적인 루프 — `while (more) fetch(++page)`
- LLM 이 결정할 게 아님

### ❌ "엑셀 row 를 LLM 한테 한 줄씩 읽혀서 정규화"
- 같은 정규화 로직(전화번호 숫자만, 주소 공백/괄호 제거) 을 LLM 이 매번 다르게 함
- `normPhone` / `cleanAddress` 함수로 1번만 정의

### ❌ "스키마 다른 8년치 xlsx 를 LLM 이 한 파일씩 처리"
- 헤더 row 위치, 컬럼 순서 차이를 표(`SCHEMA_A` / `SCHEMA_B` ...) 로 외부화
- 파일명 → schema 매핑은 스크립트의 `detectFile()` 함수

## When to break the rule

- **샘플 < 20 row** + 일회성 + 인간이 검수해야 함 → 토큰으로 처리해도 OK
- **스키마가 매번 달라서** 스크립트가 안정적이지 않음 → LLM 도움받아 스키마 발견 후 스크립트화
- **요약/큐레이션** (수치가 아니라 평가) → LLM 작업

## Checklist before you start

- [ ] 첫 응답 1~2 row 만 토큰으로 봤는가? 전체를 토큰에 넣지 않았는가?
- [ ] 페이지네이션 / numOfRows cap 을 probe 로 확인했는가?
- [ ] 정규화 (phone, address, name) 를 함수로 정의했는가?
- [ ] 결과는 JSON 으로 저장하고 토큰엔 메트릭만 출력하는가?
- [ ] 매칭 폴백 체인 (phone → addr+name → name+district) 이 명시적인가?

## Real cases (이 프로젝트)

- `scripts/ingest-postpartum-care.mts` — 1 xlsx → 473 row, 카카오 지오코딩 캐시 동반
- `scripts/ingest-postpartum-history.mts` — 14 xlsx (반기별) → 471 시설 × 시계열
- `scripts/ingest-postpartum-localdata.mts` — data.go.kr API 1014 row → 391 매칭
- `scripts/ingest-postpartum-nearby.mts` — 시설별 nearby POI 검색

이 패턴을 따른 결과: 작업 1회 토큰 비용 ~수천, 재실행 비용 0 (스크립트 그대로 실행).
