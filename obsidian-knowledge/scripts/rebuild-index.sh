#!/bin/bash
# Rebuilds vault-index.md from actual vault files
# Run: bash ~/.claude/skills/obsidian-knowledge/scripts/rebuild-index.sh

VAULT="/Users/heejinchae/Library/Mobile Documents/iCloud~md~obsidian/Documents/PARA"
INDEX="$HOME/.claude/skills/obsidian-knowledge/vault-index.md"
DATE=$(date +%Y-%m-%d)

{
echo "# Vault Note Index"
echo "> Regenerate with: \`bash ~/.claude/skills/obsidian-knowledge/scripts/rebuild-index.sh\`"
echo "> Last updated: $DATE"
echo ""
echo "Use this file to find linkable notes WITHOUT running Grep."
echo "Wiki-link syntax: \`[[Filename Without Extension]]\` — path doesn't matter if filename is unique."
echo ""
echo "---"
echo ""
echo "## 30.Resources"
find "$VAULT/30.Resources" -name "*.md" | sort | while read f; do
  name=$(basename "$f" .md)
  dir=$(dirname "$f" | sed "s|$VAULT/30.Resources||" | sed 's|^/||')
  if [ -z "$dir" ]; then
    echo "- \`$name\` (root)"
  else
    echo "- \`$name\` ($dir)"
  fi
done

echo ""
echo "## 10.Projects (main files only)"
find "$VAULT/10.Projects" -name "*.md" | grep -v "2026-" | sort | while read f; do
  name=$(basename "$f" .md)
  echo "- \`$name\`"
done

echo ""
echo "## 20.Area"
find "$VAULT/20.Area" -name "*.md" | sort | while read f; do
  name=$(basename "$f" .md)
  echo "- \`$name\`"
done
} > "$INDEX"

echo "✓ vault-index.md rebuilt at $INDEX"
