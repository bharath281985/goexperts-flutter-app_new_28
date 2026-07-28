# Investor Sidebar Design Brief

## Objective
Upgrade the existing Flutter `AppDrawer` investor experience into a polished, production-ready, role-aware sidebar inspired by the supplied dark investor menu screenshot while remaining faithful to the Go Experts app architecture and visual system.

## Target audience
Authenticated investors using the Go Experts portal to discover startups, manage deal flow, and track portfolios.

## Aesthetic direction
Professional investment workspace: compact, calm, premium, and information-dense. Use clear section hierarchy, restrained surfaces, crisp selected states, and small live-count badges. The component must look excellent in both light and dark themes. It should feel native to Go Experts, not copy the screenshot's navy/gold palette.

## Existing implementation and constraints
- Project: Flutter / Dart, Material 3, `flutter_bloc`, `go_router`.
- Main file: `E:\bhanu\goexperts_portal_app\lib\core\widgets\app_drawer.dart`.
- Theme tokens: `E:\bhanu\goexperts_portal_app\lib\app\constants\app_colors.dart`, `context.colors`, and `context.text`.
- User model: `E:\bhanu\goexperts_portal_app\lib\features\auth\domain\entities\app_user.dart`.
- Routes: `E:\bhanu\goexperts_portal_app\lib\app\router\route_names.dart`.
- Preserve unrelated user changes in this dirty worktree.
- Keep the existing role-driven `_sections` architecture and live `unreadNotifications` / `unreadMessages` badges.
- Use only existing routes. Do not introduce dead menu items. Do not add Invoices because there is no investor invoice route.
- Preserve pull-to-refresh and logout confirmation behavior.
- Tap targets must be at least 44 logical pixels.
- No new image assets are needed; use `AppAvatar`.

## Content structure
Create a dedicated investor drawer branch parallel to the founder branch.

Header:
- Compact Go Experts brand marker/title with clear investor context.
- User card with avatar, full name, investor role/headline, readable subscription plan/status if useful, and a profile completion bar driven by `profileCompletion` (clamped 0–100).

Navigation:
- Overview: Dashboard, Analytics, Notifications.
- Deal Flow: Startup Discovery, Opportunities/Deal Rooms, Due Diligence, Offers, Watchlist (Bookmarks route).
- Portfolio: Investments/Portfolio, Transactions, Reports.
- Communication: Messages, Meetings, Calendar.
- Documents: Documents.
- Finance: Wallet, Subscription.
- Account: Profile, Settings, Security, Support.

Use exact existing investor/shared routes. If a label would be misleading, prefer existing product terminology.

## Typography
Use the app text theme. Section labels should be compact uppercase with subtle tracking. User name and selected items carry the strongest weight. Avoid tiny unreadable text.

## Color direction
Use `context.colors` and `AppColors` only. Go Experts red is the accent for selection, focus, progress, and branding. Neutral theme surfaces handle the rest. Badges use semantic theme/status colors. Support dark and light themes without hardcoded screenshot colors.

## Memorable detail
A refined investor identity/profile-completion card and a slim red selected-route indicator that makes the long menu effortless to scan.

## Interaction and quality
- Current route is visually distinct.
- Long content scrolls and remains practical on short screens.
- Labels truncate safely.
- Keep code reusable; generalize founder components where clean rather than duplicating a full drawer.
- Format and analyze the changed Dart file.

## Output
Implement directly in `E:\bhanu\goexperts_portal_app\lib\core\widgets\app_drawer.dart`.
