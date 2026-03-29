---
name: obsidian-knowledge
description: Capture and save knowledge into the Obsidian PARA vault as a properly formatted markdown note with wiki-links to related existing notes. Use when the user shares an article, concept, notes, learnings, or any knowledge they want to save. Triggers on phrases like "save this", "add this to my vault", "create a note for this", "remember this knowledge", "take notes on", or when the user pastes content they clearly want preserved.
argument-hint: [topic or paste content directly]
allowed-tools: Read, Glob, Grep, Write, Bash
---

# Obsidian Knowledge Capture

Vault root: `/Users/heejinchae/Library/Mobile Documents/iCloud~md~obsidian/Documents/PARA`

## Supporting Files (read before writing)

- **[frontmatter-patterns.md](frontmatter-patterns.md)** — exact frontmatter per note type, callout styles, naming rules. Read this first.
- **[vault-index.md](vault-index.md)** — pre-built list of all existing notes. Use for wiki-links. No Grep needed.

## Process (5 steps)

### 1. Classify
Determine PARA folder and note type from `$ARGUMENTS` / user content:

| Content | Folder | `type:` |
|---------|--------|---------|
| Concept, article, reference, book | `30.Resources/[subfolder]/` | `resource` |
| Tied to active project | `10.Projects/[project]/` | no type, or project note |
| Ongoing skill/responsibility | `20.Area/` | `area` |
| Unsure / quick capture | `00.Inbox/` | `daily` |

### 2. Find links (use vault-index.md — no Grep needed)
Open `vault-index.md` and pick 2–5 notes with overlapping topic. Those become `[[wiki-links]]`.
Only Grep if the topic is highly specific and not covered by the index.

### 3. Choose filename
Follow naming rules in `frontmatter-patterns.md`. Short, searchable, no special chars except spaces/hyphens/em-dash.

### 4. Write the note
Use the correct frontmatter template from `frontmatter-patterns.md` — do NOT invent new fields.

**Resource note body pattern** (synthesize, don't dump):
```
# Title

What is this, why it matters, key takeaways. Write freely.

## Related
- [[Link1]], [[Link2]]
```

**Token-saving rules:**
- Skip empty sections
- For vocabulary/definition notes: frontmatter + definition + 1-2 examples is enough
- For raw content dumps: add frontmatter + keep content as-is, don't force structure

**Vocabulary consolidation rule:**
Do NOT create a new file per word. Instead:
- If a dated session file exists for today (e.g. `2026-03-05 Word.md`): append to it
- If no session file exists today: create `YYYY-MM-DD Word1, Word2.md`
- For orphaned/undated words: append to `10.Projects/12.IELTS 9 Capability/IELTS Vocabulary - Undated.md`
Each word = H2 heading with definition + example.

### 5. Save and report
Use Write tool. Report back:
```
✓ Saved: 30.Resources/AI/Note Title.md
✓ Links: [[Maekawa's theorem]], [[CS Intermediate]]
✓ Tags: [ai, origami]
```

## Decision: when NOT to add frontmatter
If the user just wants to dump raw content (a URL, a definition, a code snippet), skip the full template. Write the content as-is with only minimal frontmatter (`type`, `created`). Match the style of similar existing notes.

## Rebuild the index
After saving a new note, remind the user they can update the vault index:
`bash ~/.claude/skills/obsidian-knowledge/scripts/rebuild-index.sh`
