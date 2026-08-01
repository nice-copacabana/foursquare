ALTER TABLE "Match"
ADD COLUMN "externalId" TEXT,
ADD COLUMN "protocolVersion" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN "startingPlayer" TEXT NOT NULL DEFAULT 'black',
ADD COLUMN "endReason" TEXT NOT NULL DEFAULT 'abandoned',
ADD COLUMN "revision" INTEGER NOT NULL DEFAULT 0;

UPDATE "Match" SET "externalId" = "id" WHERE "externalId" IS NULL;

ALTER TABLE "Match" ALTER COLUMN "externalId" SET NOT NULL;

CREATE UNIQUE INDEX "Match_externalId_key" ON "Match"("externalId");
