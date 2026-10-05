import { sql } from "drizzle-orm";
import { index, integer, primaryKey, sqliteTable, text } from "drizzle-orm/sqlite-core";

const createdAt = integer("created_at", { mode: "timestamp_ms" })
  .notNull()
  .default(sql`(unixepoch() * 1000)`);
const updatedAt = integer("updated_at", { mode: "timestamp_ms" })
  .notNull()
  .default(sql`(unixepoch() * 1000)`);

/** Anonymous per-device account. Only the SHA-256 of the bearer token is stored. */
export const users = sqliteTable("users", {
  id: text("id").primaryKey(),
  displayName: text("display_name").notNull(),
  tokenHash: text("token_hash").notNull().unique(),
  /** Encoded in the personal QR; rotating it invalidates old QR codes. */
  inviteCode: text("invite_code").notNull().unique(),
  createdAt,
  updatedAt,
});

/** Friendship is mutual and stored as two rows (a→b and b→a) so lookups only need `user_id`. */
export const friendships = sqliteTable(
  "friendships",
  {
    userId: text("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    friendId: text("friend_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    createdAt,
  },
  (t) => [primaryKey({ columns: [t.userId, t.friendId] })],
);

/**
 * A log entry the owner chose to share. `id` is the client's local record id, so re-sending
 * the same record (offline retry queue) upserts instead of creating a duplicate.
 */
export const shares = sqliteTable(
  "shares",
  {
    id: text("id").primaryKey(),
    ownerId: text("owner_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    emoji: text("emoji").notNull(),
    name: text("name").notNull(),
    occurredAt: integer("occurred_at", { mode: "timestamp_ms" }).notNull(),
    /** `all` = every friend (broadcast); `targets` = only rows in share_targets (multicast). */
    audience: text("audience", { enum: ["all", "targets"] }).notNull(),
    createdAt,
    updatedAt,
  },
  (t) => [index("shares_owner_occurred_idx").on(t.ownerId, t.occurredAt)],
);

export const shareTargets = sqliteTable(
  "share_targets",
  {
    shareId: text("share_id")
      .notNull()
      .references(() => shares.id, { onDelete: "cascade" }),
    userId: text("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
  },
  (t) => [primaryKey({ columns: [t.shareId, t.userId] }), index("share_targets_user_idx").on(t.userId)],
);

/** One reaction per viewer per share; reacting again replaces the emoji. */
export const reactions = sqliteTable(
  "reactions",
  {
    shareId: text("share_id")
      .notNull()
      .references(() => shares.id, { onDelete: "cascade" }),
    userId: text("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    emoji: text("emoji").notNull(),
    createdAt,
    updatedAt,
  },
  (t) => [primaryKey({ columns: [t.shareId, t.userId] })],
);
