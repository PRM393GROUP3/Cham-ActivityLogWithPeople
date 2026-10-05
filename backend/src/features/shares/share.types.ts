import type { shares } from "../../infrastructure/db/schema";
import type { PublicUserDto } from "../users/user.types";

export type ShareRow = typeof shares.$inferSelect;
export type NewShareRow = typeof shares.$inferInsert;

export type Cursor = { occurredAt: Date; id: string };

export type Page<T> = { items: T[]; nextCursor: string | null };

/** A share as its owner sees it: audience settings plus who reacted. */
export type OwnShareDto = {
  id: string;
  emoji: string;
  name: string;
  occurredAt: string;
  audience: "all" | "targets";
  targetIds: string[];
  reactions: { user: PublicUserDto; emoji: string; reactedAt: string }[];
  createdAt: string;
  updatedAt: string;
};

/** A friend's share as a viewer sees it: no audience details, only reaction counts. */
export type FeedShareDto = {
  id: string;
  owner: PublicUserDto;
  emoji: string;
  name: string;
  occurredAt: string;
  reactions: { emoji: string; count: number }[];
  myReaction: string | null;
};
