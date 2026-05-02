#!/usr/bin/env bash
# Scan for the generateImageMetadata footgun in dynamic OG image routes.
# Reports sites where the function exists in a [param] route — likely the bug.
# After build, also counts how many og:image meta tags end up in prerendered HTML.
set -euo pipefail

ROOT="${1:-.}"
ERR=0
warn() { echo "  ⚠  $1"; ERR=1; }
ok()   { echo "  ✓  $1"; }

cd "$ROOT"

echo "▶ generateImageMetadata footgun 점검"
echo

# 1. Find opengraph-image / icon / apple-icon files inside dynamic routes
DYNAMIC_OG=$(find src/app \( -name 'opengraph-image.tsx' -o -name 'icon.tsx' -o -name 'apple-icon.tsx' \) 2>/dev/null | grep '\[')

if [[ -z "$DYNAMIC_OG" ]]; then
  ok "동적 라우트(`[param]`)에 image route 없음 — 점검할 게 없음."
  exit 0
fi

for f in $DYNAMIC_OG; do
  echo "── $f"
  if grep -qE 'export\s+function\s+generateImageMetadata|export\s+async\s+function\s+generateImageMetadata' "$f"; then
    # Look for the most common bug shape: returning ALL items
    if grep -qE 'load[A-Z][a-zA-Z]*\(\)\s*\.map|getAll[A-Z][a-zA-Z]*\(\)\s*\.map|getProvinces\(\)\.map' "$f"; then
      warn "generateImageMetadata가 모든 항목을 반환 — 각 페이지에 형제 페이지의 og:image 메타가 모두 박힘"
      echo "       → 함수 자체를 삭제하면 [param] 동적 경로별로 Next가 자동으로 OG 이미지 1개 생성"
    else
      warn "generateImageMetadata 정의됨 — 각 페이지가 정말로 여러 OG 이미지를 필요로 하는지 확인"
      echo "       → 시설/제품/사용자별 단일 OG면 함수 삭제 권장"
    fi
  else
    ok "generateImageMetadata 없음 — 정상"
  fi
done

# 2. After build, count og:image meta tags in a sample prerendered HTML file
echo
echo "── 빌드 산출물 og:image 메타 카운트 (샘플)"
APP_DIR=".next/server/app"
if [[ -d "$APP_DIR" ]]; then
  while IFS= read -r f; do
    count=$(grep -oE 'og:image","content":' "$f" 2>/dev/null | wc -l | tr -d ' ')
    if [[ $count -gt 5 ]]; then
      warn "$(basename "$f"): og:image 메타 ${count}개 — 비정상"
    elif [[ $count -gt 0 ]]; then
      ok "$(basename "$f"): og:image 메타 ${count}개"
    fi
  done < <(find "$APP_DIR" -name "*.rsc" -path "*place*" -o -path "*[*" -name "*.rsc" 2>/dev/null | head -10)
else
  echo "  (npm run build 안 돌렸음 — 빌드 후 재실행)"
fi

echo
exit $ERR
