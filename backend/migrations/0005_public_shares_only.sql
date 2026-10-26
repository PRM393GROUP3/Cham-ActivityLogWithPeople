-- Sharing is now Public (all friends) or Private (never uploaded). Shares that were limited to
-- selected friends are revoked instead of silently widening to all friends. Their reactions
-- are removed by ON DELETE CASCADE.
DELETE FROM `shares` WHERE `audience` = 'targets';--> statement-breakpoint
DROP TABLE `share_targets`;--> statement-breakpoint
ALTER TABLE `shares` DROP COLUMN `audience`;
