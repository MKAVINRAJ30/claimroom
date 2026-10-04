BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "item" ADD COLUMN "waitlistCount" bigint DEFAULT 0;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "waitlist_entry" (
    "id" bigserial PRIMARY KEY,
    "roomId" bigint NOT NULL,
    "itemId" bigint NOT NULL,
    "buyerName" text NOT NULL,
    "buyerToken" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "waitlist_item_idx" ON "waitlist_entry" USING btree ("itemId");


--
-- MIGRATION VERSION FOR claimroom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('claimroom', '20261004052150481', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261004052150481', "timestamp" = now();

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
