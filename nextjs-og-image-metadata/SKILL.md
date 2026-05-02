---
name: nextjs-og-image-metadata
description: Avoid the generateImageMetadata footgun in Next.js App Router. Triggers when adding opengraph-image.tsx / icon.tsx / apple-icon.tsx in a dynamic route (e.g. /[id]/), or when a Lighthouse report flags huge HTML / RSC payload sizes (200KB+) on per-item pages.
disable-model-invocation: false
---

# OG image metadata in dynamic routes

## The footgun

`generateImageMetadata()` exists for one specific case: **a single route segment that needs MULTIPLE OG images**. Most apps don't need this — Next.js auto-generates ONE OG image per dynamic-route path from the default export.

If you add `generateImageMetadata` that returns ALL items (e.g. all 472 places, all 17 provinces), Next.js attaches **every returned ID's `og:image` meta tag to every generated page**. A `/place/[id]/` page ends up with 472 `<meta property="og:image">` tags pointing at sibling pages' OG images.

Effects:
- HTML pages bloat 5–10× (470KB+ for 472-item routes)
- RSC payload bloats by the same factor (550KB+)
- LCP / FCP degrade — the document body is huge before any meaningful content
- Lighthouse "Avoid huge document size" / "Reduce initial HTML" warnings

## When you DO need generateImageMetadata

Only when one path serves multiple OG images for itself. Example: a product page that wants 3 hero variations:

```ts
// app/product/[slug]/opengraph-image.tsx
export function generateImageMetadata({ params }: { params: { slug: string } }) {
  return [
    { id: "hero", alt: "..." },
    { id: "lifestyle", alt: "..." },
    { id: "spec", alt: "..." },
  ];
}

export default function Image({ params, id }: { params: { slug: string }; id: string }) {
  // render image based on id
}
```

This produces 3 OG images per product (`/og-image-hero`, `/og-image-lifestyle`, `/og-image-spec`) and attaches all 3 to that product's page.

## The wrong pattern (the footgun)

```ts
// app/place/[id]/opengraph-image.tsx
export function generateImageMetadata() {
  // ❌ returns all 472 places — attaches 472 OG images to every place page
  return loadAllPlaces().map((p) => ({ id: p.id, alt: p.name }));
}
```

The `dynamicParams = false` and `[id]` in the route already give you per-place generation via the page's `generateStaticParams`. `generateImageMetadata` here is redundant AND harmful.

## The fix

Delete `generateImageMetadata`. Keep just the default `Image` export:

```ts
// app/place/[id]/opengraph-image.tsx
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const alt = "Default alt";
export const dynamicParams = false;

type Props = { params: Promise<{ id: string }> };

export default async function Image({ params }: Props) {
  const { id } = await params;
  // render OG image for this specific id
  return new ImageResponse(...);
}
```

That's it. Next.js generates one OG image per `[id]` and attaches one `og:image` tag.

## Verification

After removing the function, sizes should drop dramatically:

```bash
# Before
ls -la .next/server/app/your/route/[id].rsc   # 551KB
ls -la .next/server/app/your/route/[id].html  # 470KB

# After
ls -la .next/server/app/your/route/[id].rsc   # ~40KB
ls -la .next/server/app/your/route/[id].html  # ~75KB
```

## More

- `scripts/scan.sh` — find any `opengraph-image.tsx` / `icon.tsx` / `apple-icon.tsx` in dynamic routes that defines `generateImageMetadata` returning all items, and count how many `og:image` tags landed in the prerendered HTML
  ```bash
  bash ~/.claude/skills/nextjs-og-image-metadata/scripts/scan.sh /path/to/project
  ```
