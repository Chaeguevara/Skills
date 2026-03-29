# Skills

Claude Code skills for persistent knowledge and automation across every session.

## Available Skills

### `geometric-folding`
Reference knowledge base for mathematical and computational origami. Loaded automatically when any session touches folding theory.

Covers: Maekawa's theorem (`|M−V|=2`), Kawasaki's theorem (alternating angles), local foldability conditions, local foldability graphs (LFG), degree-4 vertices, layer ordering, global flat-foldability (NP-hardness), tree method, box pleating, and rigid origami.

Files: `SKILL.md`, `theorems-deep.md`

---

### `obsidian-knowledge`
Captures knowledge into the Obsidian PARA vault as a properly formatted markdown note with wiki-links to related existing notes.

Triggers on: "save this", "add this to my vault", "create a note for this", "take notes on", or pasted content to preserve.

Files: `SKILL.md`, `frontmatter-patterns.md`, `vault-index.md`

---

### `obsidian-daily`
Creates today's daily note in the Obsidian PARA vault (`00.Inbox/YYYY-MM-DD.md`). Reports the path if the note already exists; otherwise creates it from a lean template.

Files: `SKILL.md`

---

## Structure

```
skills/
├── geometric-folding/
│   ├── SKILL.md            # Main reference (auto-loaded)
│   └── theorems-deep.md    # Extended proofs & algorithms
├── obsidian-knowledge/
│   ├── SKILL.md
│   ├── frontmatter-patterns.md
│   └── vault-index.md
└── obsidian-daily/
    └── SKILL.md
```
