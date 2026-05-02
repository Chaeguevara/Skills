#!/usr/bin/env bash
# Scan for conditionally-rendered components that are statically imported.
# Pattern: `{flagOrState && <ComponentName ...>}` where ComponentName is at
# the top via a regular `import` — these are candidates for next/dynamic.
set -euo pipefail

ROOT="${1:-.}"
SRC="$ROOT/src"
[[ -d "$SRC" ]] || SRC="$ROOT"

echo "▶ 조건부 렌더 + 정적 import 후보 스캔 ($SRC)"
echo

# Find files with "use client" pragma (server components don't ship to client)
CLIENT_FILES=$(grep -rl '"use client"' "$SRC" --include='*.tsx' 2>/dev/null || true)
[[ -z "$CLIENT_FILES" ]] && { echo "client component 없음."; exit 0; }

found_any=0
for f in $CLIENT_FILES; do
  # Extract conditionally-rendered components: `{<flag> && <Capital`
  CANDIDATES=$(grep -oE '\{[a-zA-Z_]+\s*&&\s*<[A-Z][A-Za-z]+' "$f" 2>/dev/null \
    | grep -oE '<[A-Z][A-Za-z]+' | sort -u || true)
  [[ -z "$CANDIDATES" ]] && continue

  # For each candidate component name, check if statically imported
  for c in $CANDIDATES; do
    name=${c#<}
    # Look for import of this component (not type-only)
    import_line=$(grep -E "^import\s+(\{[^}]*\b$name\b[^}]*\}|$name)\s+from" "$f" 2>/dev/null || true)
    if [[ -n "$import_line" ]] && ! grep -qE "\bdynamic\(.+import.+$name" "$f"; then
      if [[ $found_any -eq 0 ]]; then echo; fi
      found_any=1
      rel="${f#$ROOT/}"
      echo "── $rel"
      echo "      <$name> 가 조건부 렌더되지만 정적 import — next/dynamic 후보"
      echo "      $import_line"
      break  # one per file is enough info
    fi
  done
done

if [[ $found_any -eq 0 ]]; then
  echo "조건부 렌더 + 정적 import 패턴 없음 (모두 항상 렌더되거나 이미 dynamic)."
fi
