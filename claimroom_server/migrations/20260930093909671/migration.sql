BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "room" (
    "id" bigserial PRIMARY KEY,
    "code" text NOT NULL,
    "title" text NOT NULL,
    "sellerName" text NOT NULL,
    "isOpen" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "room_code_idx" ON "room" USING btree ("code");


--
-- MIGRATION VERSION FOR claimroom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('claimroom', '20260930093909671', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260930093909671', "timestamp" = now();

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
