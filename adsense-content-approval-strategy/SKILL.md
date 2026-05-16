---
name: adsense-content-approval-strategy
description: Content strategy for getting a new site approved by Google AdSense on the first or second submission. Distinct from `nextjs-adsense-script` (script tag mechanics) — this skill is about what to ship, not how to wire the SDK. Triggers when applying to AdSense for a fresh site, when an application is rejected for "low value content"/"insufficient content"/"site doesn't comply with policies", when deciding which pages to expose to the AdSense crawler, or when planning the page tree for a directory/listing/database site that wants ad monetization. Cross-project — applies to any content site (blog, directory, guide hub, listing aggregator) that monetizes via AdSense.
disable-model-invocation: false
---

# AdSense Content Approval Strategy

The script tag is the easy part. The hard part is what's on the pages the AdSense crawler sees. Rejections almost always come from one of:
- Thin content (mostly UI chrome, no substance)
- Paraphrase-free reposting of source data (looks like a scraper)
- Multi-attribution per page (looks like a content farm)
- Missing E-E-A-T signals (no methodology, no about, no contact)

This skill is the checklist before you submit.

## What "thin content" actually means

AdSense rejects pages where the crawler can't tell what value the site adds over the source data. Examples that get flagged:
- `/place/123` with name, address, hours, and a map — no commentary, no comparison, no analysis
- A directory listing where each row is a verbatim copy from a public dataset
- Auto-generated `/area/{province}/{district}` pages with no content beyond a count

Fix: each indexable page must add **at least one of**:
- Comparison ("이 시설은 같은 권역 평균보다 X% 저렴합니다")
- Methodology hint ("가격은 보건복지부 반기 공시 데이터 기준")
- Curation rationale ("이 큐레이션은 가성비 상위 30곳 — 점수 기준은 [link]")
- Author POV (a 1–2 sentence editorial line — the author actually has something to say)
- Educational sidebar (a "법령 요약" / "신청 절차" box alongside the data)

## The "100% paraphrase + single attribution" rule

When the data comes from an external source:
- **0% text copy** — even short descriptions get rewritten in your own words
- **1 attribution line per page** — "출처: [source name]" with a single link, not 5 scattered
- **Add 1+ derived signal** — average, percentile, rank, similarity score, anything the source doesn't show

AdSense reviewers can tell the difference between "site with its own voice + cited sources" and "site that scraped a database". The signal is dense paraphrase + visible analysis, not the absence of citations.

## Before you submit — the checklist

1. **At least 15–20 substantive pages indexable.** Not 5 deep + 500 thin = you'll be judged on the average. If most pages are thin, deindex them (`noindex` meta) before submission and re-add later.

2. **Site nav clear from the homepage.** Reviewer should be able to reach the substantive content within 2 clicks. If your homepage is a hero + 3 buttons leading to a search interface, add a "What's here" section linking to your top guides.

3. **About / Methodology / Contact pages exist and are reachable.**
   - About: who runs this, why this exists
   - Methodology: how the data is gathered, how derived signals are computed, what the limits are
   - Contact: real email (not a form on a third-party service)

4. **Privacy + Terms pages.** AdSense requires these. Mention cookies, ad personalization, analytics.

5. **No placeholder content.** "Lorem ipsum", "TODO", "Coming soon" — all flagged. If a section isn't ready, remove it from the nav.

6. **No competing ad networks during review.** If you have other ad scripts, remove them until approval lands. Multiple ad networks looks like ad stuffing.

7. **HTTPS, no broken links, no 404s in the sitemap.** Run a crawl (Screaming Frog free version is enough) and clean up before submitting.

## E-E-A-T signals that move the needle

AdSense rolls up Google's E-E-A-T framework (Experience, Expertise, Authoritativeness, Trustworthiness). Easy wins:

- **Educational content alongside data.** A directory page becomes a guide page when you add a 200-word explainer at the top: "What to look for when choosing X, with three things this directory shows that helps."
- **Update timestamps.** "Last updated: YYYY-MM-DD" on data pages. Crawlers and reviewers both look for this.
- **Author attribution.** Even a single byline ("Curated by X") is better than no byline. Make the author page a real bio.
- **Source page per claim.** "200만원 한도는 조세특례제한법 제52조" with a link to law.go.kr. Reviewers click these.
- **Schema.org markup.** `Article`, `LocalBusiness`, `Dataset` — pick the right type. JSON-LD signals semantic richness.

## Common rejection patterns and fixes

| Rejection text | Likely cause | Fix |
|---|---|---|
| "Low-value content" | Most pages are listing rows | Add explainer header + comparison signal to top page templates |
| "Site doesn't comply with policies" (vague) | Missing About/Privacy/Contact | Add all three, link from footer |
| "Insufficient content" | Crawler saw <10 substantive pages | Deindex thin pages, focus on 15–20 deep ones |
| "Duplicate or rehashed content" | Pages are paraphrase-free copies | Rewrite descriptions in your own voice, add derived signals |
| "Site under construction" | Placeholder text, broken links | Crawl + clean, remove "coming soon" sections |

## After approval — what to keep doing

The reviewer doesn't come back, but the algorithm does:
- Don't add thin pages in bulk after approval. Auto-generated area pages should ship with at least the "what to know about X area" intro from day one.
- If you launch a new domain on the same site, the existing approval covers it but the algorithm will sample new pages. Apply the same checklist.
- Watch for "Policy violations" in AdSense → Policy center monthly. The most common late-stage hit is "deceptive site behavior" from broken CTAs or external link patterns.

## Related

- `nextjs-adsense-script` — the technical wiring (script tag, slot setup)
- `external-content-citation-policy` — how to handle source attribution without crossing into copy territory
- `seo-korean` (project-local in theme-maps) — Korean-specific SEO patterns that overlap with AdSense E-E-A-T signals
