# Startup Details redesign — refinement iteration

Objective: Refine the current Startup Details Flutter screen shown in the supplied screenshot. Change layout and styling only. Preserve every API call, Future/state path, share/save behavior, message routing, founder navigation, invest/withdraw flow, dialogs, repository call, and entity mapping.

Output: `lib/features/startup_ideas/presentation/pages/startup_details_page.dart`

Audience: Investors scanning a startup quickly on a 320–430px mobile screen.

Aesthetic: Premium, compact venture dossier using the existing GoExperts design language. More editorial and intentional than the current stacked blocks, with excellent density and no large dead area.

Key refinements from current screenshot:
- Strengthen the hero-to-identity transition. Keep cover controlled and logo overlap clean, but reduce awkward whitespace and make startup name/tagline more intentional.
- Refine metadata into compact, readable adaptive pills without long location clipping dominating the row.
- Make Overview feel like one cohesive investment snapshot rather than three isolated boxes. Maintain truthful values and progress behavior.
- Avoid showing misleading 0% progress styling when the funding target is unavailable.
- Make Team card feel complete and premium, with clear founder role/navigation.
- Place optional Problem/Solution/Business/Documents sections naturally when data exists; when absent, do not leave dead space.
- Ensure the scrolling body uses available height naturally. The bottom action bar stays anchored, but the page should not visually appear unfinished when content is sparse.
- Refine bottom Message + Invest/Withdraw actions with balanced widths and long-label safety at 320px.

Typography: Existing app typography with stronger startup title, clear section hierarchy, legible metrics, and muted supporting text.

Colors: Use `AppColors` and existing gradients/tokens in every section. No hard-coded visual colors.

Responsive: Validate at 320, 360, 375, and 430 logical px. No overflows, debug stripes, squeezed metric text, clipped actions, or obscured scroll content.

Images: Reuse existing cover/logo/avatar URLs and existing fallback treatment. No new assets.

Constraints: Layout/style changes only. Do not change APIs, parsing, callbacks, state, repository calls, navigation, save/share/message/invest/withdraw behavior, documents, or business logic. Format and run targeted Dart analysis.
