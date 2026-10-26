import { and, count, desc, eq, exists, inArray, lt, or, sql, type SQL } from "drizzle-orm";
import type { Database } from "../../infrastructure/db/client";
import { friendships, reactions, shares, users } from "../../infrastructure/db/schema";
import type { Cursor, NewShareRow, ShareRow } from "./share.types";

export type FeedRow = { share: ShareRow; owner: { id: string; displayName: string } };

export class ShareRepository {
  constructor(private readonly db: Database) {}

  // ---------- Permission rules (the single source of truth for "who can see a share") ----------

  /**
   * SQL condition on `shares`: the viewer is currently the owner's friend (every share is Public).
   * Friendship is checked live, so new friends see older shares and unfriending revokes at once.
   */
  private visibleTo(viewerId: string): SQL {
    return exists(
      this.db
        .select({ one: sql`1` })
        .from(friendships)
        .where(and(eq(friendships.userId, shares.ownerId), eq(friendships.friendId, viewerId))),
    );
  }

  /** User ids (other than the owner) allowed to see the owner's shares: their current friends. */
  async findViewerIds(ownerId: string): Promise<string[]> {
    const rows = await this.db
      .select({ id: friendships.friendId })
      .from(friendships)
      .where(eq(friendships.userId, ownerId));
    return rows.map((r) => r.id);
  }

  // ---------- Owner side ----------

  findById(id: string): Promise<ShareRow | undefined> {
    return this.db.select().from(shares).where(eq(shares.id, id)).get();
  }

  listOwned(ownerId: string, cursor: Cursor | undefined, limit: number): Promise<ShareRow[]> {
    return this.db
      .select()
      .from(shares)
      .where(and(eq(shares.ownerId, ownerId), cursor && before(cursor)))
      .orderBy(desc(shares.occurredAt), desc(shares.id))
      .limit(limit);
  }

  async upsert(data: NewShareRow): Promise<void> {
    const { id: _id, ownerId: _ownerId, ...fields } = data;
    await this.db.insert(shares).values(data).onConflictDoUpdate({ target: shares.id, set: fields });
  }

  async delete(id: string): Promise<void> {
    await this.db.delete(shares).where(eq(shares.id, id));
  }

  // ---------- Viewer side ----------

  private feedQuery() {
    return this.db
      .select({ share: shares, owner: { id: users.id, displayName: users.displayName } })
      .from(shares)
      .innerJoin(users, eq(users.id, shares.ownerId));
  }

  /** Friends' shares visible to the viewer, newest first. Own shares are excluded (not a friend of self). */
  feed(viewerId: string, cursor: Cursor | undefined, limit: number): Promise<FeedRow[]> {
    return this.feedQuery()
      .where(and(this.visibleTo(viewerId), cursor && before(cursor)))
      .orderBy(desc(shares.occurredAt), desc(shares.id))
      .limit(limit);
  }

  findVisible(id: string, viewerId: string): Promise<FeedRow | undefined> {
    return this.feedQuery()
      .where(and(eq(shares.id, id), this.visibleTo(viewerId)))
      .get();
  }

  // ---------- Reactions ----------

  async setReaction(shareId: string, userId: string, emoji: string): Promise<void> {
    const now = new Date();
    await this.db
      .insert(reactions)
      .values({ shareId, userId, emoji, createdAt: now, updatedAt: now })
      .onConflictDoUpdate({ target: [reactions.shareId, reactions.userId], set: { emoji, updatedAt: now } });
  }

  async deleteReaction(shareId: string, userId: string): Promise<boolean> {
    const rows = await this.db
      .delete(reactions)
      .where(and(eq(reactions.shareId, shareId), eq(reactions.userId, userId)))
      .returning({ shareId: reactions.shareId });
    return rows.length > 0;
  }

  reactionCounts(shareIds: string[]) {
    return this.db
      .select({ shareId: reactions.shareId, emoji: reactions.emoji, count: count() })
      .from(reactions)
      .where(inArray(reactions.shareId, shareIds))
      .groupBy(reactions.shareId, reactions.emoji);
  }

  reactionsBy(userId: string, shareIds: string[]) {
    return this.db
      .select({ shareId: reactions.shareId, emoji: reactions.emoji })
      .from(reactions)
      .where(and(eq(reactions.userId, userId), inArray(reactions.shareId, shareIds)));
  }

  reactionDetails(shareIds: string[]) {
    return this.db
      .select({
        shareId: reactions.shareId,
        emoji: reactions.emoji,
        reactedAt: reactions.updatedAt,
        user: { id: users.id, displayName: users.displayName },
      })
      .from(reactions)
      .innerJoin(users, eq(users.id, reactions.userId))
      .where(inArray(reactions.shareId, shareIds))
      .orderBy(desc(reactions.updatedAt));
  }
}

/** Keyset pagination on (occurred_at DESC, id DESC). */
const before = (c: Cursor) =>
  or(lt(shares.occurredAt, c.occurredAt), and(eq(shares.occurredAt, c.occurredAt), lt(shares.id, c.id)));
