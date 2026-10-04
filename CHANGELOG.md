# Changelog

All notable changes to the ClaimRoom project are documented in this file.

## [1.2.0] - 2026-10-04

### Added
- **Waitlist with Auto-Handover**:
  - When an item is held or sold, any buyer can join the waitlist (up to 10 entries per item).
  - When a hold ends without a sale (hold expires, buyer releases, or seller releases an abandoned hold), the earliest waitlisted buyer automatically becomes the new holder with a fresh 60-second hold and scheduled future call.
  - Buyers who already have 3 active holds are skipped and kept in queue. If no eligible buyer exists, the item safely reverts to available.
  - Waitlists are cleared automatically when an item is sold, deleted, or when the live sale ends.
  - Auto-handover logic runs in the same row-locked PostgreSQL database transaction as the release or expiry sweep.
  - Privacy: Waitlist entries are completely confidential; stream events and public item queries carry only `waitlistCount` (an integer), never buyer names or tokens.
  - Endpoints: `joinWaitlist`, `leaveWaitlist`, and `getMyWaitlist`.
  - Flutter UI: "Join waitlist" and "Leave waitlist" buttons with live position indicator ("You are #N in line"), waitlist count badges ("3 waiting"), and prominent turn notification banner ("🎉 It's your turn! You have 60 seconds to confirm").
- **QR Code Join Sharing**:
  - Added "Show QR" button next to "Copy Join Link" in the seller dashboard using `qr_flutter`.
  - Displays a high-contrast QR code encoding the buyer join link (`$origin/?code=...`) alongside the 5-character room code in large 32pt bold text.
  - Encodes the buyer join link only (never exposes the seller key).
- **Two-Layer Hold Expiry**:
  - Background `HoldExpiryFutureCall` plus locked read-sweeps on `listItems`, `getOrderSheet`, and `claimItem`.
  - Guarantees automatic hold release and auto-handover even when Serverpod future calls are disabled (e.g. Serverpod Cloud Starter).
- **Expanded Test Suite (25 Tests)**:
  - Added 7 new integration tests covering waitlist auto-handover, buyer skipping on 3 holds, read-sweep handover, concurrent release/expiry idempotency, waitlist clearing on sold/endSale, waitlist caps and uniqueness, and complete privacy sanitization.

## [1.1.0] - 2026-10-01

### Added
- **Buyer Privacy Protection**: Public item listings and room streaming events strictly sanitize private contact information (`heldByContact`, `soldToContact`, and session tokens). Buyer contacts are visible only to the verified room creator via `getOrderSheet`.
- **Session Token Identity**: Added 24-character random buyer session tokens (`heldByToken`, `soldToToken`) with cross-platform persistence. Enforces that only the exact buyer session that held an item can confirm or release it.
- **Server Hardening**:
  - `markPaid` strictly rejects payment mutations on unsold items.
  - `endSale` executes room closure and release of all active holds inside a single database transaction with `LockMode.forUpdate`.
  - `addItem` validates image URLs (HTTP/HTTPS, max 500 characters) and enforces a 50-item per-room inventory limit.
- **Trust & Safety**:
  - Prominent buyer disclaimer on room join screen regarding off-platform payments and item inspection.
  - Room info header showing seller name and creation timestamp.
  - In-app "Report this room" modal and server `reportRoom` endpoint storing verified abuse reports.
- **Early Seller Hold Release**: Sellers can release abandoned holds before the 60-second timer expires via `releaseHoldAsSeller`, immediately broadcasting `item_released` to all room attendees.
- **Buyer "My Items" Panel**: Persistent floating bottom summary and sheet showing held and confirmed purchases with live running totals.
- **"All Items Sold" Banner**: Room-wide notification banner displayed to buyers and seller when all items in the room have been claimed.
- **Full Integration Test Suite**: Expanded to 17 thorough end-to-end integration tests covering concurrency, token isolation, buyer privacy sanitization, concurrent confirm/release races, image validation, abuse reports, and seller hold releases.

### Changed
- **Model Reorganization**: Moved `room.spy.yaml` and `item.spy.yaml` from `lib/src/greetings/` to `lib/src/claimroom/`, maintaining exact database table and schema integrity.
- **Clean Template Removal**: Removed unused starter template code (`greeting_endpoint.dart`, `greeting.spy.yaml`, `greetings_screen.dart`, `sign_in_screen.dart`, `email_idp_endpoint.dart`, `jwt_refresh_endpoint.dart`).
- **Seller Key Recovery**: Added local storage helper with automatic recovery and copy prompt dialogs for seller keys.

## [1.0.0] - 2026-10-01

### Added
- **Atomic Double-Claim Prevention**: Claims run inside a database transaction with a row lock, so only one buyer can win an item. Powered by PostgreSQL database transactions using `LockMode.forUpdate`.
- **60-Second Hold Expiry via Serverpod Future Calls**: Automatic release of expired holds back to available room inventory using `HoldExpiryFutureCall`.
- **Expired Hold Fast-Path**: Allows buyers to re-claim items whose 60s hold has expired even if the background scheduled future call has not yet executed.
- **Transactional Product Deletion**: Wrapped in `session.db.transaction` with `LockMode.forUpdate` ensuring only available items can be deleted.
- **Seller Key Protection**: 16-character secret key generated for the room creator, required for all admin endpoints (`addItem`, `deleteItem`, `toggleRoomStatus`, `endSale`, `getOrderSheet`, `markPaid`). The key is never exposed to buyers.
- **Mark as Paid**: Direct resolution to the "ghost buyer" problem. Sellers can toggle paid status per item on the order sheet with live paid vs. unpaid counters and real-time broadcast events.
- **Buyer Claim Limit**: Enforced inside the claim transaction; restricts buyers to a maximum of 3 active holds simultaneously.
- **Shareable Join Link**: Support for URL query parameters (e.g. `/?code=K9X2P`) to auto-fill the join code and switch to the buyer screen. Includes a 1-tap "Copy Join Link" button on the seller dashboard.
- **Sale Ended State**: Seller can end the sale, releasing unconfirmed holds and opening the final order sheet. Connected buyers receive real-time notice and view their confirmed purchases summary.
- **Multi-Format Order Sheet Export**: 1-tap "Copy as CSV" to clipboard alongside formatted "Copy WhatsApp Summary".
- **Resilient Real-time Streaming**: Reconnection handlers with a 2-second backoff and 10-second background polling safety net for WebSocket streams.
- **Optional Image URLs**: Added optional image URL field to items with fallback rendering.
- **Visual Countdown Indicator**: Hold timer turns red when under 10 seconds remaining.
- **Comprehensive Integration Test Suite**: 8 distinct integration test scenarios covering concurrency (20 parallel claims), transactions, future calls, limits, and authentication.
