# Geometric Folding — Deep Reference

Extended proofs, worked examples, and algorithms.

---

## Maekawa's Theorem — Full Proof

**Setup**: Consider an interior vertex V with creases c₁, c₂, …, c₂ₙ (in cyclic order). Assign +1 to each mountain crease and −1 to each valley crease.

**Proof via rotation**:
When the paper is folded flat, walking around the vertex means rotating 180° each time you cross a crease. Mountain = +180°, Valley = −180°. For the paper to return to the same orientation after traversing all creases:

```
Σᵢ (±180°) ≡ 0  (mod 360°)
```

This means the net rotation is ±360° (full turn), giving:

```
(M − V) × 180° = ±360°
M − V = ±2
```

---

## Kawasaki's Theorem — Proof

**Setup**: Angles between consecutive creases at vertex V are α₁, α₂, …, α₂ₙ.

**Proof via folding map**:
Define the "folding map" as the composition of reflections across each crease line. For the paper to close flat, the composition of 2n reflections must be the identity. The net rotation accumulated by alternating +αᵢ and −αᵢ contributions must sum to zero:

```
α₁ − α₂ + α₃ − … − α₂ₙ = 0
```

This is equivalent to Σ(odd) = Σ(even) = 180°.

---

## Worked Example: Bird Base Vertex

The bird base (blintz fold) creates a degree-4 vertex with angles 90°, 90°, 90°, 90°.

- **Kawasaki check**: 90° + 90° = 90° + 90° = 180° ✓
- **Maekawa check**: need |M−V| = 2, so either 3M1V or 1M3V.
- **Valid assignments**: MMMV, MMVM, MVMM, VMMM, VVVM, VVMV, VMVV, MVVV
  (8 total satisfying Maekawa for degree 4, but layer ordering eliminates some)

---

## Worked Example: Asymmetric Degree-4 Vertex

Angles: 60°, 120°, 60°, 120° (alternating).

- **Kawasaki**: 60° + 60° = 120°, 120° + 120° = 240°. Fails! ✗
- This vertex cannot be flat-folded.

Angles: 45°, 135°, 45°, 135°.

- **Kawasaki**: 45° + 45° = 90° ≠ 180°. Fails! ✗

Angles: 60°, 120°, 60°, 120° rearranged as 60°, 60°, 120°, 120°:

- **Kawasaki**: 60° + 120° = 180°, 60° + 120° = 180°. ✓
- This arrangement (adjacent equal angles) is foldable.

---

## Layer Ordering & Penetration

After local flat-folding, assign layer numbers to each paper sector at the vertex. Two sectors cannot occupy the same layer — this is the **non-penetration constraint**.

**Algorithm (for single vertex)**:
```
1. Pick any valid MV assignment (passing Maekawa).
2. Start with sector 1 at layer 0.
3. Crossing a valley fold: layer += 1
   Crossing a mountain fold: layer -= 1
4. After full traversal, check no two sectors share a layer.
5. Normalize: shift so minimum layer = 0.
```

If traversal produces a valid (no collisions) layer stack → assignment is locally realizable.

---

## NP-Hardness of Global Flat-Foldability (Bern-Hayes 1996)

**Theorem**: Given a crease pattern (angles and MV labels), determining if it is globally flat-foldable is NP-hard.

**Reduction**: From 1-in-3 SAT. Each clause maps to a gadget in the crease pattern where satisfying the clause = valid layer ordering. The global layer consistency problem captures the satisfiability constraint.

**Implication**: No polynomial algorithm is expected for arbitrary CPs. Practical origami design relies on:
- Structured patterns (tree method, box pleating)
- Local foldability as a proxy
- Specific solvable subclasses (one-straight-cut, simple folds)

---

## Tree Method (Robert Lang's ReferenceFinder / TreeMaker)

For **point-to-point** folding problems:

1. Model desired 3D shape as a "tree" (stick figure).
2. Each branch of tree = flap of paper; length = paper allocated.
3. **Packing problem**: arrange circles (representing branch lengths) on the square sheet without overlap.
4. Generate crease pattern from circle packing via perpendicular bisectors.

Key property: a valid circle packing guarantees a flat-foldable base exists.

---

## Box Pleating

A design grid where all creases are at 0°, 45°, or 90°. Powerful because:

- Degree-4 vertices with 45° angles are always Kawasaki-satisfying.
- Layer ordering is more tractable.
- Enables complex insect models (Eric Joisel, Robert Lang).

---

## Rigid Origami

A subset where each face remains planar (no bending) during folding — only dihedral angles at creases change.

**Rigid foldability condition** (degree-4 vertex): the fold angles θᵢ at opposite creases must satisfy a specific relationship derived from the spherical linkage equations:

```
tan(θ₁/2) / tan(θ₃/2) = sin((α+β)/2) / sin((α−β)/2)
```

Where α, β are the sector angles. One degree of freedom → mechanism behavior.

**Applications**: deployable structures, solar panels, medical stents, robotics.

---

## Key References

| Author | Contribution |
|--------|-------------|
| Maekawa Jun | Mountain-valley parity theorem |
| Kawasaki Toshikazu | Alternating angle theorem |
| Bern & Hayes (1996) | NP-hardness of global flat-foldability |
| Justin Jacques | Non-crossing conditions, global constraints |
| Robert Lang | Tree method, ReferenceFinder, TreeMaker software |
| Erik Demaine | Computational origami, complexity results |
| Tomohiro Tachi | Rigid origami, Origamizer software |
