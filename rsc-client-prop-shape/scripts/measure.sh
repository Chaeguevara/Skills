#!/usr/bin/env bash
# Measure HTML/RSC payload size for a Next.js page after build.
# Helps identify which prerendered pages are bloated by oversized client props.
set -euo pipefail

ROOT="${1:-.}"
LIMIT_KB="${2:-200}"

APP_DIR="$ROOT/.next/server/app"
[[ -d "$APP_DIR" ]] || { echo "❌ $APP_DIR not found — run 'npm run build' first"; exit 1; }

LIMIT_BYTES=$((LIMIT_KB * 1024))
ERR=0

echo "▶ Prerendered HTML/RSC sizes (limit: ${LIMIT_KB} KB)"
echo

# .html (RSC inlined) and .rsc (separate flight payload)
while IFS= read -r f; do
  bytes=$(wc -c < "$f")
  kb=$((bytes / 1024))
  rel="${f#$APP_DIR/}"
  if [[ $bytes -gt $LIMIT_BYTES ]]; then
    printf "  ⚠  %6s KB  %s\n" "$kb" "$rel"
    ERR=1
  else
    printf "  ✓  %6s KB  %s\n" "$kb" "$rel"
  fi
done < <(find "$APP_DIR" \( -name "*.html" -o -name "*.rsc" \) -size +0 | sort)

echo
if [[ $ERR -eq 0 ]]; then
  echo "All prerendered pages under ${LIMIT_KB} KB."
else
  echo "Files above limit may be shipping too-rich props."
  echo "→ See SKILL.md: project to compact shape, or split fetch from /data/*.json"
fi
exit $ERR
