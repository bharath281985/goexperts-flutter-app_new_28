# Flutter Broken API Closure Report

## 4 Broken APIs Fixed to 100% Operational Status

1. **Subscription Gate Bypass (B1)**:
   - **Root Cause**: `user.subscriptionPlan ?? 'active'` treated null subscription plans as active.
   - **Fix**: Null/empty subscription plan correctly returns `SubscriptionGateStatus.none` when user has no active server plan, sending un-subscribed users to subscription onboarding.
   - **Verified**: User without subscription cannot bypass paywall to access dashboard.

2. **Role Selection Hardcoded to Freelancer (B2 & B3)**:
   - **Root Cause**: Signup and role selection updated local state only without passing role to `POST /auth/register` and `PUT /auth/me`.
   - **Fix**: Role parameter passed explicitly to `_api.signup` and `selectRole()` issues `PUT /auth/me` to update database user role.
   - **Verified**: Client, Investor, and Founder selections persist to MySQL/Prisma backend.

3. **File Uploads Sending JSON Path (B4)**:
   - **Root Cause**: Uploaders POSTed `{ "filePath": "..." }` instead of multipart file bytes.
   - **Fix**: Replaced JSON body calls with `FileUploadHelper.uploadUrl()` using `MultipartFile.fromFile` and `FormData`.
   - **Verified**: Profile photo, resume, pitch deck, and document uploads transmit binary stream to `/files/upload`.

4. **Support Ticket Reply Sending Static Text (M2)**:
   - **Root Cause**: Reply action posted static fallback string.
   - **Fix**: Wired `_replyCtrl.text.trim()` to `POST /support/tickets/:id/reply`.
   - **Verified**: Custom user reply is transmitted and ticket thread updates.
