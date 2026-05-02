#!/usr/bin/env bash
# Scan a Next.js project for useSearchParams usages that may break SSG.
# Reports each call site and tells you whether it appears to be inside a
# Suspense boundary or a force-dynamic page.
set -euo pipefail

ROOT="${1:-.}"
SRC="$ROOT/src"
[[ -d "$SRC" ]] || SRC="$ROOT"

echo "▶ useSearchParams scan ($SRC)"
echo

MATCHES=$(grep -rEln 'useSearchParams\s*\(' "$SRC" --include='*.tsx' --include='*.ts' 2>/dev/null || true)
if [[ -z "$MATCHES" ]]; then
  echo "No useSearchParams usages found."
  exit 0
fi

for f in $MATCHES; do
  echo "── $f"
  # Show line numbers of the calls
  grep -n 'useSearchParams\s*(' "$f" | sed 's/^/    /'
  echo

  # Heuristic: is the file or its declared page wrapped in Suspense?
  if grep -qE 'export\s+const\s+dynamic\s*=\s*"force-dynamic"' "$f"; then
    echo "    ✓  page is force-dynamic — Suspense not required"
  elif grep -qE '<Suspense\b' "$f"; then
    echo "    ✓  Suspense boundary in the same file"
  else
    # Check for sibling page.tsx that might wrap it
    DIR=$(dirname "$f")
    if grep -qE '<Suspense\b' "$DIR"/*.tsx 2>/dev/null; then
      echo "    ?  Suspense in sibling file — verify the right component is wrapped"
    else
      echo "    ⚠  no Suspense or force-dynamic detected in $f"
      echo "       → if this is a static page, build will fail, OR page silently opts out of SSG"
      echo "       → fix: see SKILL.md (window.location workaround) or wrap in <Suspense>"
    fi
  fi
  echo
done
