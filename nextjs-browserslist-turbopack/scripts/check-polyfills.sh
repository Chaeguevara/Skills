#!/usr/bin/env bash
# Detect legacy-target polyfills in a Next.js production build.
# Run after `npm run build`.
set -euo pipefail

ROOT="${1:-.}"
CHUNK_DIR="$ROOT/.next/static/chunks"

if [[ ! -d "$CHUNK_DIR" ]]; then
  echo "❌ $CHUNK_DIR not found — run 'npm run build' first." >&2
  exit 1
fi

# Polyfill markers (the polyfill body usually contains the method name as a string)
PATTERNS=(
  'Array.prototype.at'
  'Array.prototype.flat'
  'Array.prototype.flatMap'
  'Object.fromEntries'
  'Object.hasOwn'
  'String.prototype.trimStart'
  'String.prototype.trimEnd'
)

ERR=0
echo "▶ Polyfill 점검 ($CHUNK_DIR)"
echo

for p in "${PATTERNS[@]}"; do
  hits=$(grep -lE "$p" "$CHUNK_DIR"/*.js 2>/dev/null || true)
  if [[ -n "$hits" ]]; then
    echo "  ⚠  $p — 다음 chunk에 폴리필 포함:"
    echo "$hits" | sed 's/^/      /'
    ERR=1
  else
    echo "  ✓  $p — 폴리필 없음"
  fi
done

echo
if [[ $ERR -eq 0 ]]; then
  echo "모든 modern method 가 폴리필 없이 사용됨."
else
  echo "→ '.browserslistrc' 파일을 repo 루트에 두고 'Chrome >= 88, Safari >= 14' 등 모던 타겟 명시"
  echo "→ package.json 의 browserslist 필드는 Next 16 Turbopack 에서 무시될 수 있음"
fi
exit $ERR
