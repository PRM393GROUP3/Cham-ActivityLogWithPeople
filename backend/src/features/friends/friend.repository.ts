import { and, desc, eq, or } from "drizzle-orm";
import type { Database } from "../../infrastructure/db/client";
import { friendships, users } from "../../infrastructure/db/schema";

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

  /** Removes the friendship in both directions. Returns false if they weren't friends. */
  async remove(a: string, b: string): Promise<boolean> {
    const deleted = await this.db
      .delete(friendships)
      .where(
        or(
          and(eq(friendships.userId, a), eq(friendships.friendId, b)),
          and(eq(friendships.userId, b), eq(friendships.friendId, a)),
        ),
      )
      .returning({ userId: friendships.userId });
    return deleted.length > 0;
  }
}
