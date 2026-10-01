# Changelog

All notable changes to the ClaimRoom project are documented in this file.

## [1.0.0] - 2026-10-01

### Added
- **Atomic Double-Claim Prevention**: Powered by PostgreSQL database transactions using `LockMode.forUpdate` ensuring zero double-sells even during simultaneous claim spikes.
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
