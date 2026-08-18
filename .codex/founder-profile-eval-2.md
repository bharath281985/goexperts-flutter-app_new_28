# Evaluation — Attempt 2

## Overall Verdict: NEEDS REVISION

## Overall Assessment

The revised founder profile now has the requested startup-details hierarchy: a controlled cover with overlap avatar, startup-led identity, metadata chips, Overview, funding, Team, skill chips, details, and bottom Message/Follow actions. It has a stronger investor-quality dossier character and preserves the profile’s visual system, but the financial component currently presents an endless loading-style bar rather than meaningful funding progress, and the three-column Overview is overly compressed at 320 px.

This is a source-level Flutter evaluation. No runnable Flutter host was supplied, so screenshots were unavailable; responsive dimensions, layout constraints, and callback/data wiring were inspected directly.

## Scores

| Criterion | Score | Status | Weight | Notes |
|-----------|-------|--------|--------|-------|
| Design Quality | 1/3 | FAIL | HIGH | The dossier direction is strong, but a permanent indeterminate funding bar labelled “Goal —” breaks the credibility and coherence of the key financial section. |
| Originality | 2/3 | PASS | HIGH | The startup-details composition is a deliberate adaptation of the investor premium language, with its own cover, identity chips, funding card, and founder Team treatment. |
| Craft | 1/3 | PASS | MEDIUM | Long identity text, locations, chips, detail values, and action labels are bounded. However, at 320 px the three-column metric tiles leave only about 69 px of usable text width after padding. |
| Functionality | 1/3 | PASS | MEDIUM | Share, save, overflow, Message, and mapped primary action retain their callbacks, but the funding visualization conveys a false loading/progress state and founder reviews are no longer rendered. |

## What's Working Well

- The 2.45:1 cover is controlled rather than oversized: at 320 px it is about 131 px high, and the 80 px avatar overlap plus 54 px following inset preserves clear separation from the identity content.
- The three 42 px cover controls require 142 px including gaps; with 16 px right inset they remain separate from the 88 px avatar cluster on a 320 px screen.
- Startup name, supporting headline, location, chip labels, contact values, and team name all have `Expanded` or explicit line/ellipsis constraints. The bottom action row gives Message and the mapped Follow/Unfollow primary action equal, accessible 50 px targets.
- The implementation preserves `onPrimaryAction`, `onMessage`, `onBookmark`, `onShare`, and the existing FollowManager/BookmarkManager wiring. Endpoints and payloads are unchanged. The public-profile parsing additions only normalize presentation fields already returned by the founder payload (industry map, stage, team label, and primary goals); no request contract changed. `git diff --check` passes.

## Issues Found

### Issue 1: Funding progress is permanently indeterminate on the public founder path

- **What**: `data.stats` for a public founder provides `Startup`, `Stage`, `Team`, and `Raised`, but no `Goal`/`Target`. `_founderView` still renders the Funding progress card whenever `Raised` exists and sets `LinearProgressIndicator.value` to `null` when no goal is present. It then displays “Goal —”.
- **Where**: `_founderView()` funding card and `_founderNumericValue()` in `profile_view.dart`; the founder `stats` map in `public_profile_page.dart`.
- **Why it matters**: The bar animates indefinitely like a loading indicator on a fully loaded profile, while communicating no actual funding progress. That undermines the premium startup-dossier feel and makes a primary financial signal ambiguous.
- **Suggested fix**: Render a determinate progress bar only when an already-returned target/goal value is available and parsed. Otherwise replace the bar with a static Raised summary (or an explicit “Funding target not public” treatment), without inventing a goal or changing any endpoint/payload.

### Issue 2: Three Overview columns are too compressed on a 320 px device

- **What**: With 16 px page padding and 8 px AppCard padding, the 320 px layout has roughly 272 px inner width. The three-column calculation produces tiles about 85 px wide and ~69 px of text width after tile padding.
- **Where**: The Overview `LayoutBuilder` in `_founderView()`.
- **Why it matters**: Values such as `6–10 members` and longer stage names are forced into very small title text columns. The two-line ellipsis prevents a RenderFlex overflow, but it still makes core metrics difficult to scan and can truncate the meaningful portion of a value.
- **Suggested fix**: Use two columns at compact widths (or a minimum tile width with `Wrap`), switching to three only when each value column is comfortable. Keep the current truncation safeguards for unusually long content.

### Issue 3: Founder reviews are silently omitted by the specialised view

- **What**: `ProfileView` still receives `reviews`, and the generic and investor branches render them, but `_founderView()` does not render a reviews section.
- **Where**: `_founderView()` in `profile_view.dart`.
- **Why it matters**: This is a content regression from the previous shared profile experience and removes an existing trust signal from a public founder/startup profile.
- **Suggested fix**: Add a compact Reviews section beneath Profile details (or before the bottom action card) when `reviews.isNotEmpty`, reusing the existing `_review()` renderer and preserving the loaded data/callback flow.

## Priority Fixes for Next Attempt

1. Do not show an indeterminate funding-progress bar when no target exists; present a static no-target financial state instead.
2. Make Overview responsive: use two tiles per row at 320–360 px, increasing to three only when the metric values have enough width.
3. Restore the conditional founder reviews block using the existing reviews data and `_review()` renderer.

## API / Callback Integrity

Confirmed: public-profile endpoints, payloads, repositories, navigation, share/save/message/follow callbacks, and manager state contracts are preserved. The parser changes remain presentation-only, exposing existing returned fields.

## Should the next attempt REFINE or PIVOT?

REFINE. The startup-details direction is appropriate and substantially closer to the investor-quality reference; correct the financial-state semantics, compact metric density, and review parity without changing the overall composition.
