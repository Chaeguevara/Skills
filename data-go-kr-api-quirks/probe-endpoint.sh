#!/usr/bin/env bash
# data.go.kr 엔드포인트 probe — 새 데이터셋 활용신청 후 동작하는 path/params 발견용.
#
# 사용:
#   export ENC_KEY='W0e...%3D%3D'   # 포털에서 발급받은 ENC 키 verbatim
#   ./probe-endpoint.sh https://apis.data.go.kr/1741000/postpartum_care
#
# 출력: 각 시도된 path × HTTP code × 응답 첫 200자.
# 200 = 정답, 404 = 잘못된 path, 500 = path 맞고 params 부족, 401 = 인증 문제.

set -e

if [ -z "${ENC_KEY:-}" ]; then
  echo "ERROR: export ENC_KEY first (URL-encoded service key from data.go.kr)" >&2
  exit 1
fi

BASE_URL="${1:-}"
if [ -z "$BASE_URL" ]; then
  echo "Usage: ENC_KEY=... $0 <base-url>" >&2
  echo "  example: ENC_KEY=... $0 https://apis.data.go.kr/1741000/postpartum_care" >&2
  exit 1
fi

echo "=== probing: $BASE_URL ==="
echo

# 시도 1: minimal — 어떤 path가 200/500 을 주는지
echo "--- Phase 1: discover operation path (200=found, 500=path-ok-params-bad) ---"
for op in "" "/info" "/list" "/getList" "/get" "/search" "/v1" "/getInfo" "/items" "/all" "/history"; do
  url="${BASE_URL}${op}?serviceKey=${ENC_KEY}"
  out=$(curl -sS -o /tmp/probe.txt -w "%{http_code}" "$url")
  body=$(head -c 120 /tmp/probe.txt | tr '\n' ' ')
  printf "  [%s]  %-20s → %s\n" "$out" "${op:-/}" "$body"
done

echo
echo "--- Phase 2: try additional params on best-looking path (use op=$BEST or override below) ---"
echo "If you saw 200 above, run e.g.:"
echo "  curl -sS '${BASE_URL}/info?serviceKey=\${ENC_KEY}&pageNo=1&numOfRows=5' | head -c 2000"
echo
echo "Common gotchas:"
echo "  - numOfRows is silently capped at 100 (paginate via pageNo)"
echo "  - ENC key has %2F %2B %3D — pass verbatim, do NOT --data-urlencode"
echo "  - Activation propagation 1~2hr after 승인 — 401 may resolve with time"
