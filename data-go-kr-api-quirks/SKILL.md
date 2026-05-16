---
name: data-go-kr-api-quirks
description: data.go.kr (Korean public data portal) API integration gotchas. ENC vs DEC service keys, activation propagation delay, hidden numOfRows server cap, operation path discovery. Triggers when calling apis.data.go.kr/* endpoints, getting 401/500 errors despite valid keys.
---

# data.go.kr API integration

Korean public data portal (data.go.kr) APIs have several non-obvious gotchas that waste hours.

**Bundled tools** (in this skill directory):
- `probe-endpoint.sh` — bash probe for `/info` `/list` `/v1` etc. operation paths. Usage: `ENC_KEY=... ./probe-endpoint.sh https://apis.data.go.kr/{org}/{service}`
- `ingest-skeleton.mts` — copy-paste TypeScript ingest with pagination + matching fallback chain. Replace ENDPOINT, schema, MATCHING_KEY.

## 1. ENC vs DEC keys — pass ENC verbatim

The portal gives you two keys per service:

```
일반 인증키 (Encoding): W0ezcasstqRA...%2FEXVI0imN...%3D%3D
일반 인증키 (Decoding): W0ezcasstqRA.../EXVI0imN...==
```

ENC has `/` `+` `=` already URL-encoded as `%2F` `%2B` `%3D`.

**Pass ENC verbatim** in the URL query string:
```bash
curl "https://apis.data.go.kr/.../info?serviceKey=${ENC_KEY}"
```

**Do NOT** use `--data-urlencode` with ENC — it re-encodes `%` to `%25` causing double-encoding → 401.

Use DEC only when:
- Calling from a tool that does its own URL encoding (`curl --data-urlencode "serviceKey=${DEC_KEY}"`)
- Header-based auth (rare)

## 2. Activation propagation delay

After clicking "활용 신청" and getting "승인" status, the API may return **401 Unauthorized for 1~2 hours** while propagation completes.

If you're sure the key is right and the service is approved:
- Check activation start date — if today, wait 1~2 hours
- Sometimes only some endpoints (`/info`) are propagated; others (`/history`) work immediately

## 3. numOfRows is silently capped at 100

```bash
curl ".../info?numOfRows=2000"   # returns only 100 items
```

Server caps `numOfRows` at 100 silently — no error, just truncated response. **Always paginate**:

```ts
const PER_PAGE = 100;
let page = 1, total = 0;
const all: Item[] = [];
while (page <= 30) {
  const j = await fetch(`...&numOfRows=${PER_PAGE}&pageNo=${page}`).then(r => r.json());
  const items = j.response?.body?.items?.item ?? [];
  total = j.response?.body?.totalCount ?? total;
  all.push(...items);
  if (items.length === 0 || all.length >= total) break;
  page++;
}
```

## 4. Operation path discovery

The dataset page shows "End Point: `https://apis.data.go.kr/1741000/postpartum_care`" but the actual path is `/info` or `/history` etc.

```bash
# Probe paths systematically
for op in "" "/v1" "/getList" "/list" "/info" "/get"; do
  echo "--- $op ---"
  curl -sS -o /tmp/p -w "%{http_code}\n" \
    "https://apis.data.go.kr/.../postpartum_care${op}?serviceKey=${ENC}"
done
```

- **404 "API not found"** = wrong path
- **500 "Unexpected errors"** = path exists but params wrong (good signal — try minimal `?serviceKey=` only)
- **401** = path exists, auth issue (key invalid OR not yet propagated)
- **200** = winner

## 5. Param trial & error

Sometimes adding `?type=json&pageNo=1` causes 401 while `?serviceKey=...` alone returns 200. Then later both work. This is propagation lag, not a real auth issue. **Bisect params** when 401 appears mid-development:

```bash
for q in "serviceKey" "serviceKey&pageNo=1" "serviceKey&numOfRows=10" "serviceKey&type=json"; do
  qs=$(echo "$q" | sed "s|serviceKey|serviceKey=${ENC}|")
  out=$(curl -sS -o /tmp/r -w "%{http_code}" "${URL}?${qs}")
  echo "[${out}] $q"
done
```

## 6. Real datasets worth knowing

| 데이터셋 ID | 이름 | Endpoint | 특징 |
|---|---|---|---|
| 15154981 | 건강_산후조리업 조회서비스 | `/1741000/postpartum_care/info` | 매일 갱신, 영업상태 + 인허가일자 + 정원 + 인력 |
| LOCALDATA 시리즈 | 음식점/숙박/카페/미용/약국... | `/1741000/{category}/info` | 동일 패턴, 카테고리만 다름 |

LOCALDATA 시리즈는 모두 같은 패턴 — 산후조리원 ingest 스크립트를 그대로 재활용 가능. xlsx ingest 와 달리 매일 자동 갱신되므로 운영상 유리.

## Checklist before debugging auth

- [ ] Service approved on data.go.kr console (status: "승인")
- [ ] Activation start date is past (not future or today)
- [ ] Using ENC key verbatim in URL (no `--data-urlencode`)
- [ ] Probing operation paths systematically (`/info`, `/list`, `/v1`)
- [ ] Pagination implemented (numOfRows ≤ 100)
- [ ] Tried minimal `?serviceKey=` only — if that 401's, key/account issue
