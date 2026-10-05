import { and, count, desc, eq, exists, inArray, lt, notInArray, or, sql, type SQL } from "drizzle-orm";
import type { Database } from "../../infrastructure/db/client";
import { friendships, reactions, shares, shareTargets, users } from "../../infrastructure/db/schema";
import type { Cursor, NewShareRow, ShareRow } from "./share.types";

export type FeedRow = { share: ShareRow; owner: { id: string; displayName: string } };

export class ShareRepository {
  constructor(private readonly db: Database) {}

  // ---------- Permission rules (the single source of truth for "who can see a share") ----------

  /**
   * SQL condition on `shares`: the viewer is currently the owner's friend AND the share is either
   * broadcast or targets them. Friendship is checked live, so unfriending revokes access at once.
   */
  private visibleTo(viewerId: string): SQL {
    return and(
      exists(
        this.db
          .select({ one: sql`1` })
          .from(friendships)
          .where(and(eq(friendships.userId, shares.ownerId), eq(friendships.friendId, viewerId))),
      ),
      or(
        eq(shares.audience, "all"),
        exists(
          this.db
            .select({ one: sql`1` })
            .from(shareTargets)
            .where(and(eq(shareTargets.shareId, shares.id), eq(shareTargets.userId, viewerId))),
        ),
      ),
    )!;
  }

  /** Subquery of user ids (other than the owner) allowed to see a share. */
  private viewersOf(shareId: string) {
    return this.db
      .select({ id: friendships.friendId })
      .from(friendships)
      .innerJoin(shares, eq(shares.ownerId, friendships.userId))
      .where(
        and(
          eq(shares.id, shareId),
          or(
            eq(shares.audience, "all"),
            exists(
              this.db
                .select({ one: sql`1` })
                .from(shareTargets)
                .where(and(eq(shareTargets.shareId, shares.id), eq(shareTargets.userId, friendships.friendId))),
            ),
          ),
        ),
      );
  }

  async findViewerIds(shareId: string): Promise<string[]> {
    return (await this.viewersOf(shareId)).map((r) => r.id);
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

  async findTargetIds(shareId: string): Promise<string[]> {
    const rows = await this.db
      .select({ id: shareTargets.userId })
      .from(shareTargets)
      .where(eq(shareTargets.shareId, shareId));
    return rows.map((r) => r.id);
  }

  /**
   * Creates or replaces a share and its target list in one atomic batch. Targets are filtered to
   * the owner's current friends, and reactions from users who can no longer see it are dropped.
   */
  async upsert(data: NewShareRow, targetIds: string[] | null): Promise<void> {
    const { id, ownerId, ...fields } = data;
    await this.db.batch([
      this.db.insert(shares).values(data).onConflictDoUpdate({ target: shares.id, set: fields }),
      this.db.delete(shareTargets).where(eq(shareTargets.shareId, id)),
      this.db.insert(shareTargets).select(
        this.db
          .select({ shareId: sql<string>`${id}`.as("share_id"), userId: friendships.friendId })
          .from(friendships)
          // `targetIds` is null for broadcast: match nothing so no target rows are written.
          .where(and(eq(friendships.userId, ownerId), inArray(friendships.friendId, targetIds ?? []))),
      ),
      this.db
        .delete(reactions)
        .where(and(eq(reactions.shareId, id), notInArray(reactions.userId, this.viewersOf(id)))),
    ]);
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
