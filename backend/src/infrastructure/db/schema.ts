import { sql } from "drizzle-orm";
import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";

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
