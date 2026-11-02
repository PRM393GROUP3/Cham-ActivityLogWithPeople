import type { users } from "../../infrastructure/db/schema";

export type UserRow = typeof users.$inferSelect;
export type NewUserRow = typeof users.$inferInsert;

/** The caller's own profile. `inviteCode` is what the personal QR encodes. */
export type MeDto = {
  id: string;
  displayName: string;
  avatarEmoji: string | null;
  /** Uploaded avatar image path (`/api/avatars/...`); takes precedence over `avatarEmoji`. */
  avatarUrl: string | null;
  inviteCode: string;
  createdAt: string;
};

/** How other users appear to you (friends, share owners, reactors). */
export type PublicUserDto = {
  id: string;
  displayName: string;
  avatarEmoji: string | null;
  avatarUrl: string | null;
};

/** The `users` columns behind a PublicUserDto; select these and map with `toPublicUserDto`. */
export type PublicUserRow = { id: string; displayName: string; avatarEmoji: string | null; avatarKey: string | null };
