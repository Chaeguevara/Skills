#!/usr/bin/env bash
# Verify deterministic builds: run a build/ingest command twice and diff the
# output directory. Exit non-zero if any byte differs.
#
# Usage:
#   bash verify.sh "<command>" <output-dir>
#
# Example:
#   bash verify.sh "npm run ingest:postpartum-care" data/parenting
#   bash verify.sh "npm run build && cp -r .next/server/app /tmp/.next-app" /tmp/.next-app
set -euo pipefail

CMD="${1:-}"
OUT="${2:-}"

if [[ -z "$CMD" || -z "$OUT" ]]; then
  echo "Usage: bash verify.sh '<command>' <output-dir>" >&2
  exit 2
fi

if [[ ! -d "$OUT" ]]; then
  echo "Output directory does not exist yet: $OUT — running command first..." >&2
  bash -c "$CMD"
fi

if [[ ! -d "$OUT" ]]; then
  echo "❌ Output directory still missing after first run: $OUT" >&2
  exit 1
fi

SNAPSHOT=$(mktemp -d -t ssg-verify-XXXXXX)
trap 'rm -rf "$SNAPSHOT"' EXIT

echo "▶ Snapshot 1: copying $OUT → $SNAPSHOT/run1"
cp -R "$OUT" "$SNAPSHOT/run1"

echo "▶ Re-running: $CMD"
bash -c "$CMD" >/dev/null

echo "▶ Snapshot 2: copying $OUT → $SNAPSHOT/run2"
cp -R "$OUT" "$SNAPSHOT/run2"

echo "▶ Diffing snapshots..."
if diff -rq "$SNAPSHOT/run1" "$SNAPSHOT/run2" > "$SNAPSHOT/diff.txt"; then
  echo "✓ Builds are deterministic."
else
  echo "⚠ Builds differ:"
  cat "$SNAPSHOT/diff.txt"
  echo
  echo "Common causes (see SKILL.md → Sources of nondeterminism):"
  echo "  - Math.random in build code"
  echo "  - Date.now / new Date in build code"
  echo "  - readdirSync without sort"
  echo "  - Promise.all collecting results without sorting"
  exit 1
fi
