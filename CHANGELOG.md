# Changelog

All notable changes to the ClaimRoom project are documented in this file.

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
