import { sql } from "drizzle-orm";
import { integer, primaryKey, sqliteTable, text } from "drizzle-orm/sqlite-core";

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
