BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "item" (
    "id" bigserial PRIMARY KEY,
    "roomId" bigint NOT NULL,
    "name" text NOT NULL,
    "price" double precision NOT NULL,
    "quantity" bigint NOT NULL,
    "status" text NOT NULL,
    "heldBy" text,
    "holdExpiresAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "item_room_idx" ON "item" USING btree ("roomId");


--
-- MIGRATION VERSION FOR claimroom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('claimroom', '20260930120815343', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260930120815343', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
