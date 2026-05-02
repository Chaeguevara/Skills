#!/usr/bin/env bash
# Check that Korean web fonts in a Next.js project are configured to avoid CLS.
set -euo pipefail

ROOT="${1:-.}"
SRC="$ROOT/src"
[[ -d "$SRC" ]] || SRC="$ROOT"
ERR=0
warn() { echo "  ⚠  $1"; ERR=1; }
ok()   { echo "  ✓  $1"; }

echo "▶ Korean font CLS audit ($SRC)"
echo

# Korean font names that can cause big CLS if mishandled
KR_FONTS='Noto_Sans_KR|Noto_Serif_KR|Nanum_Gothic|Nanum_Myeongjo|Black_Han_Sans|Gothic_A1|Pretendard|Spoqa'

# Find files that import a Korean font
FILES=$(grep -rEln "$KR_FONTS" "$SRC" --include='*.ts' --include='*.tsx' 2>/dev/null || true)

if [[ -z "$FILES" ]]; then
  echo "  No Korean font imports detected. Nothing to audit."
  exit 0
fi

for f in $FILES; do
  echo "── $f"

  # Extract the next/font config block
  CONTENT=$(awk "/$KR_FONTS\\(/,/\\}\\);/" "$f")

  # display
  if grep -qE 'display:\s*"optional"' <<< "$CONTENT"; then
    ok "display: 'optional' — minimal CLS"
  elif grep -qE 'display:\s*"swap"' <<< "$CONTENT"; then
    warn "display: 'swap' — Korean glyph swap will cause CLS up to 0.2+. Use 'optional'."
  elif grep -qE 'display:\s*"block"' <<< "$CONTENT"; then
    warn "display: 'block' — invisible text up to 3s, hurts FCP. Use 'optional' for Korean."
  else
    warn "no explicit display set — defaults to 'auto' (≈ block). Set display: 'optional'."
  fi

  # preload
  if grep -qE 'preload:\s*false' <<< "$CONTENT"; then
    ok "preload: false — large Korean woff2 won't be preloaded"
  elif grep -qE 'preload:\s*true' <<< "$CONTENT"; then
    warn "preload: true on Korean font — 1-2MB preload tanks LCP. Set preload: false."
  else
    warn "no explicit preload — defaults to true. Add preload: false for Korean fonts."
  fi

  # Check for explicit subsets (latin only is fine)
  if grep -qE 'subsets:\s*\[' <<< "$CONTENT"; then
    ok "subsets specified"
  else
    warn "no subsets: ['latin'] — may include unnecessary subsets, increasing fetch size"
  fi
  echo
done

if [[ $ERR -eq 0 ]]; then
  echo "Korean font config OK."
else
  echo "Issues found — see SKILL.md for the fix."
fi
exit $ERR
