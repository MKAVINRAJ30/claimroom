# ClaimRoom: Real-Time First-to-Claim Sales for Small Sellers

ClaimRoom is a full-stack Flutter and Serverpod application that enables small sellers (e.g., selling through Instagram Lives and WhatsApp groups) to run live claim-based sales without spreadsheets or chat confusion.

## Core Features & Architecture

1. **Room & Item Management**:
   - Sellers create a live room with a 5-character join code (`Room` model).
   - Sellers add products with name, price, and stock (`Item` model).
   - Instant Demo Seeding: 1-click seeding of demo items for fast walkthroughs.

2. **Atomic Double-Claim Prevention**:
   - Handled inside PostgreSQL transactions (`session.db.transaction`) using `LockMode.forUpdate`.
   - Even when multiple buyers tap "Claim" at the exact same millisecond, row-level locks ensure only one claim succeeds. Double-selling is mathematically impossible.

3. **60-Second Hold & Future Calls**:
   - Winning claims enter a 60-second hold state (`Item.status = 'held'`).
   - Serverpod `HoldExpiryFutureCall` is scheduled (`session.serverpod.futureCalls.callWithDelay(...)`).
   - If the buyer does not confirm within 60 seconds, the future call automatically expires the hold and releases the item back to `'available'`.
   - If the buyer confirms, the item is locked as `'sold'`, and the future call is cleanly canceled.

4. **Real-Time Streaming**:
   - Serverpod streaming endpoint (`client.room.streamRoom(roomId)`) broadcasts live room events (`RoomEvent`).
   - Real-time updates push directly to all connected buyers and sellers when items are added, claimed, held, confirmed, or released.

5. **Order Sheet & WhatsApp Export**:
   - Sellers view an aggregated order sheet (`OrderSheet`) grouped by buyer.
   - 1-tap "Copy WhatsApp Summary" formats a clean order breakdown ready to post into WhatsApp groups or buyer DMs.

## Project Structure

- `claimroom_server/`: Serverpod backend (PostgreSQL, future calls, streaming endpoints, transactions).
- `claimroom_client/`: Auto-generated client library shared with Flutter.
- `claimroom_flutter/`: Material 3 Flutter UI (Seller dashboard, Buyer live room, Order sheet, real-time counters).

## Developer Workflow & MCP Instructions

The user starts the server and Flutter app with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then STOP and ask the user to start it. NEVER start the server yourself. The Flutter app is started along with it, or can be launched from the MCP tool `spawn_flutter_app`.

While running, `serverpod start` watches for file changes to run incremental code generation and hot reload both the server and the Flutter app.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line when available:
- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `claimroom_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the server cannot be started at all, fall back to the CLI in the server package:
- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; `serverpod start` applies pending migrations when it boots the server.

Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package.

Checklist after doing changes, in this order:
- `dart analyze` (CLI)
- `dart format` (CLI)
- `create_migration` and `apply_migrations` (MCP - only if necessary)
- Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically). Will also hot restart Flutter app
- Run tests, if applicable (`dart test` in the server package)
- Check `serverpod` MCP `tail_server_logs` and `tail_flutter_logs` for any issues.

If the user asks you to test the app:
1. Use `get_flutter_app_dtd` (`serverpod` MCP) to get the Flutter app's DTD
2. Pass the DTD to `connect_dart_tooling_daemon` (`dart` MCP) to connect to the app
3. Use `flutter_driver` (`dart` MCP) to navigate through the app

The app is launched from `claimroom_flutter/lib/driver.dart`, which starts the Flutter driver extension with text entry emulation turned off so the app stays usable by hand. To let the driver type, set `enableTextEntryEmulation: true` there and `hot_restart` the app.
