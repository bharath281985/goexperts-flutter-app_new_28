# Founder public profile redesign

Objective: Redesign the founder public-profile presentation in the existing Flutter app. The current screen is visually cramped, has clipping/overflow, weak hierarchy, an oversized generic cover, and awkwardly compressed actions/stats.

Audience: Investors, clients, freelancers, and founders viewing a founder/startup profile on mobile.

Target implementation:
- Primary: lib/features/profile/presentation/widgets/profile_view.dart
- Supporting page only if required for app-bar/actions: lib/features/profile/presentation/pages/public_profile_page.dart

Aesthetic direction: Premium startup dossier. Clean white/soft-neutral surfaces, restrained GoExperts red accents, dark readable typography, rounded cards, disciplined spacing, and clear founder/startup hierarchy. Avoid a generic social-media profile clone.

Content structure:
1. Compact app bar with back, founder name, share, and overflow/save access where appropriate.
2. Cover image area with a controlled aspect ratio and graceful fallback; no oversized empty or distorted region.
3. Founder identity block with avatar overlapping the cover, verification badge, founder name, startup name, concise role/industry/stage line, and location.
4. Primary actions with Follow and Message prominent; Save accessible without squeezing the primary actions.
5. Metrics card/strip for Startup, Stage, Team, and Raised. Values must wrap or scale safely; never clip.
6. About section with readable paragraph spacing and sensible empty state.
7. Founder goals/expertise rendered as well-spaced chips from existing `skills` data.
8. Optional contact/details content already supported by ProfileViewData should remain available and visually coherent.

Typography: Use the app typography. Strong identity title, medium section titles, muted metadata, readable body. Avoid tiny labels.

Colors: Existing AppColors and GoExperts primary red; neutral background/surfaces; semantic verified and status colors.

Responsive requirements:
- Must look correct at 320, 360, 375, and 430 logical px widths.
- No right-edge overflow, clipped action buttons, vertical debug stripes, or squeezed metric values.
- Long names, startup names, location, and 6-10 member labels must wrap/truncate intentionally.

Constraints:
- Founder layout only. Do not regress the recently redesigned investor layout or freelancer/company layouts.
- Preserve every callback and behavior: onPrimaryAction, onMessage, onBookmark, onShare, FollowManager state, BookmarkManager state, API parsing, navigation, and contact workflow.
- Do not change endpoints, payloads, repositories, or API parsing unless required solely to expose already-returned presentation data.
- Reuse existing components and design tokens where practical.
- No new raster assets required; use existing cover/avatar behavior and graceful code-native fallbacks.
- Format and run targeted Dart analysis.
