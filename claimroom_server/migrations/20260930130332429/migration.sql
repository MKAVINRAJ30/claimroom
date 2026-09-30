BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "item" ADD COLUMN "heldByContact" text;
ALTER TABLE "item" ADD COLUMN "soldTo" text;
ALTER TABLE "item" ADD COLUMN "soldToContact" text;
ALTER TABLE "item" ADD COLUMN "soldAt" timestamp without time zone;

--
-- MIGRATION VERSION FOR claimroom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('claimroom', '20260930130332429', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260930130332429', "timestamp" = now();

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
