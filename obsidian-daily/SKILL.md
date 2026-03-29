---
name: obsidian-daily
description: Create today's daily note in the Obsidian PARA vault. Checks if today's note already exists; if yes, reports its path. If no, creates it from the lean tpl-daily template.
argument-hint: (none needed)
allowed-tools: Read, Write, Bash
disable-model-invocation: true
---

# Obsidian Daily Note

Vault root: `/Users/heejinchae/Library/Mobile Documents/iCloud~md~obsidian/Documents/PARA`
Daily notes folder: `00.Inbox/`

## Process

1. Determine today's date (YYYY-MM-DD) and day name (dddd).
2. Check if `00.Inbox/YYYY-MM-DD.md` already exists using Read or Bash `ls`.
3. **If exists:** Report the path — do nothing else.
4. **If not exists:** Create the file with the template below.

## Template (inline — no Templater dependency)

Replace `YYYY-MM-DD` and `dddd` with actual values before writing.

```markdown
---
type: daily
date: YYYY-MM-DD
tags: [daily]
---

# YYYY-MM-DD dddd

## Focus
-

## Tasks
- [ ]

## Log

```

## Report format

```
✓ Created: 00.Inbox/2026-03-05.md
```
or
```
ℹ Already exists: 00.Inbox/2026-03-05.md
```
