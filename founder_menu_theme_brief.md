# Theme-aware founder menu polish

## Objective
Refine the existing founder/client-style Flutter drawer so all navigation colors come from the application theme and central `AppColors` palette.

## Scope
- Modify `lib/core/widgets/app_drawer.dart` only unless a small supporting change is truly needed.
- Keep the recently implemented founder information architecture and all routes/behaviour unchanged.

## Color requirements
- The drawer background and menu text/icon colors must respond to light and dark `ColorScheme` values.
- Use `context.colors` / `context.theme` for neutral surface and text colors.
- Use `AppColors.primary` / the themed primary for selected states and menu badges; use a subtle primary-tinted selected row background so the selected item reads clearly.
- Section headers should use the themed muted/on-surface-variant color.
- Avoid raw `Color(0x...)` values in generic drawer rendering. Preserve the approved branded header gradient in `AppColors.primaryGradient`.
- Keep sufficient contrast and a touch target-friendly compact visual style.

## Constraints
- Do not change client, founder, or shared routes or their functional behavior.
- Preserve badges, expansion state behavior, refresh and logout.
- Format and analyze the changed source.
