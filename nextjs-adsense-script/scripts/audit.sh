#!/usr/bin/env bash
# Audit AdSense integration in a Next.js project.
# Run from project root: bash audit.sh
set -euo pipefail

ROOT="${1:-.}"
ERR=0
warn() { echo "  ⚠  $1"; ERR=1; }
ok()   { echo "  ✓  $1"; }

echo "▶ AdSense integration audit ($ROOT)"

# 1. ads.txt exists and references a publisher
if [[ -f "$ROOT/public/ads.txt" ]]; then
  if grep -qE '^google\.com,\s*pub-[0-9]+,\s*DIRECT,\s*f08c47fec0942fa0' "$ROOT/public/ads.txt"; then
    ok "public/ads.txt: present + valid format"
  else
    warn "public/ads.txt exists but format looks off (expected: google.com, pub-XXX, DIRECT, f08c47fec0942fa0)"
  fi
else
  warn "public/ads.txt missing — AdSense will flag earnings at risk"
fi

# 2. NEXT_PUBLIC_ADSENSE_CLIENT in .env.example
if [[ -f "$ROOT/.env.example" ]]; then
  if grep -q "NEXT_PUBLIC_ADSENSE_CLIENT" "$ROOT/.env.example"; then
    ok ".env.example: NEXT_PUBLIC_ADSENSE_CLIENT documented"
  else
    warn ".env.example: NEXT_PUBLIC_ADSENSE_CLIENT not documented"
  fi
fi

# 3. Detect the data-nscript anti-pattern: <Script src=...adsbygoogle.js />
LAYOUTS=$(find "$ROOT/src/app" -maxdepth 3 -name "layout.tsx" 2>/dev/null || true)
if [[ -n "$LAYOUTS" ]]; then
  for f in $LAYOUTS; do
    # Look for next/script Script component pointing at adsbygoogle
    if grep -nE '<Script[^>]+adsbygoogle\.js' "$f" >/dev/null 2>&1; then
      warn "$f: <Script src=...adsbygoogle.js> detected — adds data-nscript, breaks AdSense validator"
    fi
    # Look for at least one of the supported patterns
    if grep -qE 'adsbygoogle\.js' "$f"; then
      if grep -qE '(<script[^>]+adsbygoogle\.js|createElement\(.script.\))' "$f"; then
        ok "$f: AdSense loaded via raw <script> or DOM injection"
      fi
    fi
  done
else
  echo "  (no layout.tsx found under src/app/)"
fi

# 4. Preconnect for AdSense — speeds up lazy-load
if grep -rqE 'rel="preconnect"[^>]*pagead2\.googlesyndication\.com' "$ROOT/src" 2>/dev/null; then
  ok "preconnect to pagead2.googlesyndication.com present"
else
  warn "no preconnect to pagead2.googlesyndication.com — lazy-loaded AdSense will pay full DNS+TLS cost"
fi

echo
if [[ $ERR -eq 0 ]]; then
  echo "AdSense audit passed."
else
  echo "AdSense audit: issues found above."
fi
exit $ERR
