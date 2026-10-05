import type { users } from "../../infrastructure/db/schema";

export type UserRow = typeof users.$inferSelect;
export type NewUserRow = typeof users.$inferInsert;

/** The caller's own profile. `inviteCode` is what the personal QR encodes. */
export type MeDto = {
  id: string;
  displayName: string;
  inviteCode: string;
  createdAt: string;
};

/** How other users appear to you (friends, share owners, reactors). */
export type PublicUserDto = {
  id: string;
  displayName: string;
};
