import { and, desc, eq, inArray, or } from "drizzle-orm";
import type { Database } from "../../infrastructure/db/client";
import { friendships, reactions, shares, shareTargets, users } from "../../infrastructure/db/schema";

export type FriendRow = { id: string; displayName: string; since: Date };

export class FriendRepository {
  constructor(private readonly db: Database) {}

  list(userId: string): Promise<FriendRow[]> {
    return this.db
      .select({ id: users.id, displayName: users.displayName, since: friendships.createdAt })
      .from(friendships)
      .innerJoin(users, eq(users.id, friendships.friendId))
      .where(eq(friendships.userId, userId))
      .orderBy(desc(friendships.createdAt));
  }

  find(userId: string, friendId: string): Promise<FriendRow | undefined> {
    return this.db
      .select({ id: users.id, displayName: users.displayName, since: friendships.createdAt })
      .from(friendships)
      .innerJoin(users, eq(users.id, friendships.friendId))
      .where(and(eq(friendships.userId, userId), eq(friendships.friendId, friendId)))
      .get();
  }

  /** Inserts both directions; a no-op if they are already friends. */
  async add(a: string, b: string): Promise<void> {
    const createdAt = new Date();
    await this.db
      .insert(friendships)
      .values([
        { userId: a, friendId: b, createdAt },
        { userId: b, friendId: a, createdAt },
      ])
      .onConflictDoNothing();
  }

  /**
   * Removes the friendship in both directions and revokes everything it granted: each side is
   * dropped from the other's share targets, and their reactions on each other's shares are deleted.
   * Runs as one D1 batch (atomic). Returns false if they weren't friends.
   */
  async remove(a: string, b: string): Promise<boolean> {
    const sharesOf = (ownerId: string) =>
      this.db.select({ id: shares.id }).from(shares).where(eq(shares.ownerId, ownerId));
    const [deleted] = await this.db.batch([
      this.db
        .delete(friendships)
        .where(
          or(
            and(eq(friendships.userId, a), eq(friendships.friendId, b)),
            and(eq(friendships.userId, b), eq(friendships.friendId, a)),
          ),
        )
        .returning({ userId: friendships.userId }),
      this.db
        .delete(shareTargets)
        .where(
          or(
            and(eq(shareTargets.userId, b), inArray(shareTargets.shareId, sharesOf(a))),
            and(eq(shareTargets.userId, a), inArray(shareTargets.shareId, sharesOf(b))),
          ),
        ),
      this.db
        .delete(reactions)
        .where(
          or(
            and(eq(reactions.userId, b), inArray(reactions.shareId, sharesOf(a))),
            and(eq(reactions.userId, a), inArray(reactions.shareId, sharesOf(b))),
          ),
        ),
    ]);
    return deleted.length > 0;
  }
}
