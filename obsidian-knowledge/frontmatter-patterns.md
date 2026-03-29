# Frontmatter Patterns

## CRITICAL OBSERVATIONS

1. **Many real notes have NO frontmatter** — bare content is fine for quick captures.
2. **Only 3 fields are required** — `type`, `created`, `tags`. Don't invent extra fields.
3. **Content quality matters more than structure** — rich synthesized prose beats template-filled shells.

---

## New Standard (3 fields for all notes)

```yaml
type: resource | project | area | daily | meeting
created: YYYY-MM-DD
tags: [tag1, tag2]
```

**Dropped fields (do NOT use):** `priority`, `review-cycle`, `topic`, `source`, `updated`, `completed`, `area`, `week`, `title`, `startTime`, `endTime`, `allDay`

---

## By Note Type

### `type: resource` — 30.Resources/
```yaml
---
type: resource
created: YYYY-MM-DD
tags: [tag1, tag2]
---
```

### `type: project` — 10.Projects/
```yaml
---
type: project
status: active
created: YYYY-MM-DD
deadline: YYYY-MM-DD   # omit if no deadline
tags: [tag1, tag2]
---
```
- `status`: active | paused | done

### `type: area` — 20.Area/
```yaml
---
type: area
created: YYYY-MM-DD
tags: [tag1, tag2]
---
```

### `type: daily` — 00.Inbox/ (dated notes)
```yaml
---
type: daily
date: YYYY-MM-DD
tags: [daily]
---
```

### `type: meeting` — meeting notes
```yaml
---
type: meeting
date: YYYY-MM-DD
tags: []
---
```

---

## Dataview Inline Relations (use in body, not frontmatter)

Use `::` inline syntax for area/relation fields:
```markdown
## Links
- Area:: [[Career]]
- Related:: [[Result pattern]], [[Maekawa's theorem]]
```

Double-colon `::` syntax creates Dataview properties. This replaces `area:` as a frontmatter field.

---

## Resource Note Body Pattern

```markdown
# Title

What is this, why it matters, key takeaways. Write freely.

## Related
- [[Link1]], [[Link2]]
```

Skip empty sections. For vocabulary/definition notes, frontmatter + definition + 1-2 examples is enough.

---

## Vocabulary Consolidation Pattern

**Do NOT create a new file per vocabulary word.** Instead:
- Check if a running vocabulary session file exists for today/this session
- If yes: **append** the new word as an `## Word` section to that file
- If no: create `YYYY-MM-DD Word1, Word2.md` in the project folder
- For undated/orphaned words: append to `IELTS Vocabulary - Undated.md`

This keeps individual word files from proliferating.

---

## Existing Subfolders in 30.Resources/

- `AI/` — Claude, LLMs, AI tools
- `Books/` — Book summaries
- `CS/` — Computer Science fundamentals
- `Csharp/` — C# / .NET topics
- `English/` — Language / IELTS
- `Origami/` — Flat-foldability theorems and origami math (Maekawa, Justin, LFFG)

Create a new subfolder only if 2+ notes belong to the same topic.

---

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Resource | `Topic Name.md` | `Result pattern.md` |
| Daily work | `YYYY-MM-DD Description.md` | `2026-01-28 HKMC Meeting.md` |
| Vocabulary session | `YYYY-MM-DD Word1, Word2.md` | `2026-01-16 Imperious, Obfuscate.md` |
| Project main | Matches folder name | `12.IELTS 9 Capability.md` |
| Books | Full title with author | `Good Strategy Bad Strategy — 리처드 루멜트.md` |
