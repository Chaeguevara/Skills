---
name: macos-nfd-korean-filenames
description: macOS filesystem stores Korean filenames in NFD (decomposed) form, but JS source code is NFC. Direct regex matching on filenames silently fails. Triggers when iterating files via readdirSync and matching Korean patterns ("2018년_상반기" etc).
---

# macOS NFD vs JS NFC

## Symptom

```ts
const files = readdirSync("data/raw");
const matches = files.filter((f) => /2018년_상반기/.test(f));
// matches.length === 0  even though the file visibly exists
```

You see the file in `ls`. The regex looks right. But the filter returns nothing.

## Root cause

macOS APFS / HFS+ stores Korean filenames in **NFD (Normalization Form Decomposed)** — `년` is stored as `ㄴ` + `ㅕ` + `ㄴ` jamo.

JS source code (and your regex literal) is in **NFC (Composed)** — `년` is one code point.

Same visible character, different byte sequence. Regex fails.

## Fix

Normalize the filename to NFC before matching:

```ts
const files = readdirSync("data/raw");
for (const rawFile of files) {
  const f = rawFile.normalize("NFC");
  if (/2018년_상반기/.test(f)) { /* ... */ }
}
```

Pass `rawFile` (NFD) to `readFileSync` / `join` etc. — those use the original bytes. Use the NFC version only for **matching/comparing** against source-code strings.

## Why this is sneaky

- `console.log(f)` prints the same characters either form
- `f.length` differs (NFD has more code points) but you rarely check
- `f === "2018년_상반기"` returns false even when visually identical
- Linux filesystems store NFC by default — bug only reproduces on macOS, hides in CI

## Verification

```ts
const f = readdirSync(".")[0];
console.log("NFC:", f.normalize("NFC").length);
console.log("NFD:", f.normalize("NFD").length);
// On macOS Korean filenames: NFC < NFD
```

## Real case

`scripts/ingest-postpartum-history.mts` filename → period detection. Initial regex matched 0 of 14 Korean xlsx files. Adding `rawFile.normalize("NFC")` recovered all matches.

## Generalization

Same applies to:
- Reading from a clipboard
- File uploads from a Mac to a Linux server (the upload preserves NFD)
- Comparing user-typed search query (NFC) against indexed filenames (NFD)
- Korean URL path segments (some browsers normalize to NFC, others don't)

When in doubt, **normalize both sides to NFC** before string operations.
