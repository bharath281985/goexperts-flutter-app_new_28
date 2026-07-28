# Client dashboard quick-action cards

## Objective
Refine the **client dashboard** quick-action cards so they are readable, easy to scan and touch, and feel like a coherent part of the existing Flutter product. The work is a targeted UI fix, not a dashboard redesign.

## Audience
Clients who manage projects, hiring, meetings and payments from the mobile-first dashboard.

## Existing application context
- Flutter application. Change the existing components in their established locations.
- Client surface: `lib/features/client_dashboard/presentation/pages/client_home_page.dart`.
- Shared base widget: `lib/core/widgets/dashboard_action_button.dart`. It is also used on freelancer and founder dashboards; preserve its current appearance for those roles.
- Existing colour system: `lib/app/constants/app_colors.dart`; use its semantic palette in the client implementation where appropriate.
- Do not overwrite unrelated existing work in this dirty worktree.

## Observed defects to resolve
- The cards are fixed at 132 x 60, yet multi-word labels are restricted to one line and ellipsized.
- Saturated full-card fills and strong coloured shadows make the action strip noisy.
- The strip lacks a client-facing section heading and visual context.

## Design direction
Create a calm, premium operational quick-actions surface: soft neutral card backgrounds, concise coloured icon tiles, dark readable labels, generous touch targets, and subtle borders/shadows. This should harmonize with the existing dark client hero without competing with it.

## Content and interaction structure
- Add a concise "Quick actions" section heading and a short supportive subtitle before the six actions.
- Preserve the six existing action labels, icons and callbacks exactly; do not invent routes or change action behavior.
- On phone layouts, render a balanced two-column, fluid-width grid. Support wider layouts responsively.
- Use a client-specific configuration/variant of the shared button or a client-scoped composition; do not regress existing freelancer/founder action strips.
- Ensure labels can render on two lines without ellipsis and cards meet an approximately 88px or greater touch-friendly height.

## Typography and colour
- Follow the app's existing Material typography and spacing conventions.
- Headline is clear, compact and semibold/bold; subtitle uses the app's subtle text colour.
- Use `AppColors` tokens for background/text/borders where available. Accent colours belong chiefly to icon containers, not the whole card.

## Memorable element
The action set should read as a composed control panel: a restrained grid with distinct icon colour cues, rather than six competing buttons.

## Image needs
None.

## Output
Implement directly in the existing Flutter files, with minimal scoped changes. Run the relevant formatter and static analysis/tests available in the repository.
