---
name: geometric-folding
description: Reference knowledge base for geometric folding theory. Use when the user asks about origami math, crease patterns, flat-foldability, Maekawa's theorem, Kawasaki's theorem, local foldability conditions, mountain-valley assignments, or any computational/mathematical origami topic.
argument-hint: [specific theorem, concept, or folding problem]
allowed-tools: Read
---

# Geometric Folding — Knowledge Reference

Authoritative knowledge base for mathematical and computational origami. Load this skill whenever the session touches folding theory, crease patterns, or origami algorithms.

---

## Core Vocabulary

| Term | Definition |
|------|-----------|
| **Crease pattern (CP)** | Flat diagram showing all fold lines on the unfolded sheet |
| **Mountain fold (M)** | Fold away from you; ridge faces up |
| **Valley fold (V)** | Fold toward you; groove faces up |
| **MV assignment** | Labeling of every crease as M or V |
| **Interior vertex** | A vertex strictly inside the sheet (not on boundary) |
| **Flat-foldable** | A CP that can fold into a flat (zero-thickness) state |
| **Simple vertex** | A single interior vertex with `2n` creases emanating from it |
| **Developable surface** | A surface that can be unrolled flat without distortion |

---

## Maekawa's Theorem

> **At every interior vertex of a flat-foldable crease pattern, the number of mountain folds and valley folds differ by exactly 2.**

Formally, for a vertex with `M` mountain folds and `V` valley folds:

```
|M - V| = 2
```

Equivalently:
- `M - V = +2`  or  `M - V = -2`
- Total creases at the vertex = `M + V = 2n` (always even)
- So valid combinations for `2n` creases: `(n+1, n-1)` or `(n-1, n+1)`

### Consequences
- A vertex with an **odd** number of creases cannot be flat-foldable.
- The parity of M and V is always different (one odd, one even) — unless `2n` allows it.
- Maekawa is a **necessary** condition for flat-foldability, not sufficient on its own.

### Proof sketch
Traverse around the vertex; each M contributes +1 and each V contributes -1 to a winding argument. For the paper to close flat, the net signed count must equal ±2 (one full ±180° turn excess).

---

## Kawasaki's Theorem

> **A single interior vertex with 2n creases is flat-foldable iff the alternating sum of consecutive angles equals 180°.**

For angles `α₁, α₂, …, α₂ₙ` going around the vertex:

```
α₁ - α₂ + α₃ - α₄ + … + α₂ₙ₋₁ - α₂ₙ = 0
```

Which is equivalent to:

```
α₁ + α₃ + α₅ + … = α₂ + α₄ + α₆ + … = 180°
```

(Odd-indexed angles sum to 180°; even-indexed angles also sum to 180°.)

### Key Points
- Kawasaki gives a **geometric** condition; Maekawa gives a **combinatorial** (MV) condition.
- Both must hold simultaneously for local flat-foldability.
- For `2n = 4` creases (degree-4 vertex): exactly one angle condition — simplest case.

---

## Local Foldability

**Local flat-foldability** asks: can a single interior vertex fold flat, ignoring the rest of the sheet?

### Necessary & Sufficient Conditions (single vertex)
1. **Even degree** — vertex has `2n` creases (odd degree → never flat-foldable).
2. **Kawasaki's theorem** — alternating angles sum to 180°.
3. **Maekawa's theorem** — `|M - V| = 2`.

All three must hold. Together they are sufficient for a **single vertex** in isolation.

### Local Foldability Graph (LFG)
A tool for reasoning about valid MV assignments at a vertex:

- **Nodes** = possible MV assignment sequences around the vertex.
- **Edges** = valid transitions (assignments consistent with foldability rules).
- The graph encodes all 2^(2n) possible MV combos but pruned by Maekawa and layer ordering constraints.

For a degree-4 vertex (`n=2`): 16 total → 6 satisfy Maekawa → further reduced by layer conditions.

**Layer ordering constraint**: When two layers of paper overlap after folding, their stacking order must be consistent (no paper passing through paper). This is the hardest part of global foldability.

---

## Single-Vertex Flat-Foldability Algorithm

```
Input: angles α₁…α₂ₙ around a vertex
1. Check degree is even. If odd → NOT foldable.
2. Check Kawasaki: Σ odd angles = Σ even angles = 180°. If not → NOT foldable.
3. Enumerate MV assignments satisfying Maekawa (|M-V|=2).
4. For each candidate: check layer ordering (no penetration).
5. Any valid assignment found → vertex IS locally flat-foldable.
```

---

## Global Flat-Foldability

Global flat-foldability (entire crease pattern, not just one vertex) is **NP-hard** in general (Bern & Hayes 1996).

### Global Conditions
- Every interior vertex must satisfy Kawasaki and Maekawa locally.
- MV assignments must be **globally consistent** — no paper-penetration anywhere.
- **Justin's non-crossing condition**: crease lines from different vertices must not cause paper layers to intersect.

### Simple Foldability
For **simple folds** (one straight crease across the whole sheet): always foldable. Complexity arises with multiple intersecting creases.

---

## Degree-4 Vertex — Key Special Case

Most common in origami design. Four creases, angles `α, β, α, β` where `α + β = 180°` (Kawasaki auto-satisfied when opposite angles are equal).

MV assignments satisfying Maekawa: `3M1V` or `1M3V`.

**Rigid foldability** of degree-4 vertex: requires one crease to bisect the angle between the other two (the "ruling" crease). Enables rigid origami (no face bending).

---

## Big-Little-Big Angle Pattern

At any flat-foldable vertex, the creases can be ordered so that there is always a "small" angle sandwiched between two larger angles. The fold direction of the bisected crease is forced:

- The single crease inside the smallest sector **must differ** in MV from the two creases bounding that sector.
- This gives a local forcing rule used in MV assignment algorithms.

---

## Key Theorems Summary

| Theorem | Statement | Type |
|---------|-----------|------|
| Maekawa | `|M−V|=2` at every interior vertex | Combinatorial (MV) |
| Kawasaki | Alternating angles = 180° | Geometric |
| Bern-Hayes | Global flat-foldability is NP-hard | Complexity |
| Justin | Non-crossing condition for global consistency | Global |

---

## Supporting File

See **[theorems-deep.md](theorems-deep.md)** for extended proofs, worked examples, and algorithm pseudocode.
