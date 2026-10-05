import type { Notify } from "../../infrastructure/realtime/realtime";
import { ConflictError, ForbiddenError, NotFoundError } from "../../shared/errors/app-error";
import type { FeedRow, ShareRepository } from "./share.repository";
import type { PageQuery, UpsertShareInput } from "./share.schema";
import type { Cursor, FeedShareDto, OwnShareDto, Page, ShareRow } from "./share.types";

const encodeCursor = (s: ShareRow) => `${s.occurredAt.getTime()}_${s.id}`;

const decodeCursor = (cursor: string | undefined): Cursor | undefined => {
  if (!cursor) return undefined;
  const sep = cursor.indexOf("_");
  return { occurredAt: new Date(Number(cursor.slice(0, sep))), id: cursor.slice(sep + 1) };
};

const toPage = <R, T>(rows: R[], limit: number, shareOf: (r: R) => ShareRow, items: T[]): Page<T> => ({
  items,
  nextCursor: rows.length === limit ? encodeCursor(shareOf(rows.at(-1)!)) : null,
});

const groupBy = <T>(rows: T[], key: (r: T) => string) => {
  const map = new Map<string, T[]>();
  for (const r of rows) map.set(key(r), [...(map.get(key(r)) ?? []), r]);
  return map;
};

export class ShareService {
  constructor(
    private readonly repo: ShareRepository,
    private readonly notify: Notify,
  ) {}

  // ---------- Owner side: /api/shares ----------

  async listOwned(ownerId: string, page: PageQuery): Promise<Page<OwnShareDto>> {
    const rows = await this.repo.listOwned(ownerId, decodeCursor(page.cursor), page.limit);
    return toPage(rows, page.limit, (r) => r, await this.toOwnDtos(rows));
  }

  async getOwned(ownerId: string, id: string): Promise<OwnShareDto> {
    const row = await this.repo.findById(id);
    if (!row || row.ownerId !== ownerId) throw new NotFoundError("Share", id);
    return (await this.toOwnDtos([row]))[0]!;
  }

  /**
   * Idempotent create-or-replace keyed by the client's record id, so the offline queue can resend
   * safely. Re-sending with a different `targetIds` updates who can see it.
   */
  async upsert(ownerId: string, id: string, input: UpsertShareInput): Promise<{ share: OwnShareDto; created: boolean }> {
    const existing = await this.repo.findById(id);
    if (existing && existing.ownerId !== ownerId) throw new ConflictError(`Share id '${id}' is already in use`);

    const viewersBefore = existing ? await this.repo.findViewerIds(id) : [];
    const now = new Date();
    await this.repo.upsert(
      {
        id,
        ownerId,
        emoji: input.emoji,
        name: input.name,
        occurredAt: input.occurredAt,
        audience: input.targetIds ? "targets" : "all",
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      },
      input.targetIds,
    );
    const viewersAfter = new Set(await this.repo.findViewerIds(id));

    this.notify(viewersAfter, { type: "share.upserted", id });
    this.notify(
      viewersBefore.filter((v) => !viewersAfter.has(v)),
      { type: "share.removed", id },
    );
    return { share: await this.getOwned(ownerId, id), created: !existing };
  }

  /** Revokes the share for everyone. Deleting an unknown id succeeds, so queued deletes can be retried. */
  async remove(ownerId: string, id: string): Promise<void> {
    const existing = await this.repo.findById(id);
    if (!existing) return;
    if (existing.ownerId !== ownerId) throw new NotFoundError("Share", id);

    const viewers = await this.repo.findViewerIds(id);
    await this.repo.delete(id);
    this.notify(viewers, { type: "share.removed", id });
  }

  // ---------- Viewer side: /api/feed ----------

  async feed(viewerId: string, page: PageQuery): Promise<Page<FeedShareDto>> {
    const rows = await this.repo.feed(viewerId, decodeCursor(page.cursor), page.limit);
    return toPage(rows, page.limit, (r) => r.share, await this.toFeedDtos(viewerId, rows));
  }

  async getFeedItem(viewerId: string, id: string): Promise<FeedShareDto> {
    return (await this.toFeedDtos(viewerId, [await this.requireVisible(viewerId, id)]))[0]!;
  }

  async react(viewerId: string, id: string, emoji: string): Promise<FeedShareDto> {
    const row = await this.requireVisible(viewerId, id);
    await this.repo.setReaction(id, viewerId, emoji);
    this.notify([row.share.ownerId], { type: "reaction.changed", shareId: id });
    return (await this.toFeedDtos(viewerId, [row]))[0]!;
  }

  async unreact(viewerId: string, id: string): Promise<void> {
    const row = await this.requireVisible(viewerId, id);
    if (await this.repo.deleteReaction(id, viewerId)) {
      this.notify([row.share.ownerId], { type: "reaction.changed", shareId: id });
    }
  }

  /** 404 (not 403) when hidden, so non-viewers can't probe which share ids exist. */
  private async requireVisible(viewerId: string, id: string): Promise<FeedRow> {
    const row = await this.repo.findVisible(id, viewerId);
    if (!row) {
      const own = await this.repo.findById(id);
      if (own?.ownerId === viewerId) throw new ForbiddenError("This is your own share; use /api/shares");
      throw new NotFoundError("Share", id);
    }
    return row;
  }

  // ---------- Mapping ----------

  private async toOwnDtos(rows: ShareRow[]): Promise<OwnShareDto[]> {
    if (!rows.length) return [];
    const ids = rows.map((r) => r.id);
    const [reactions, targets] = await Promise.all([
      this.repo.reactionDetails(ids),
      Promise.all(rows.map((r) => (r.audience === "targets" ? this.repo.findTargetIds(r.id) : []))),
    ]);
    const reactionsByShare = groupBy(reactions, (r) => r.shareId);

    return rows.map((r, i) => ({
      id: r.id,
      emoji: r.emoji,
      name: r.name,
      occurredAt: r.occurredAt.toISOString(),
      audience: r.audience,
      targetIds: targets[i]!,
      reactions: (reactionsByShare.get(r.id) ?? []).map((x) => ({
        user: x.user,
        emoji: x.emoji,
        reactedAt: x.reactedAt.toISOString(),
      })),
      createdAt: r.createdAt.toISOString(),
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  private async toFeedDtos(viewerId: string, rows: FeedRow[]): Promise<FeedShareDto[]> {
    if (!rows.length) return [];
    const ids = rows.map((r) => r.share.id);
    const [counts, mine] = await Promise.all([this.repo.reactionCounts(ids), this.repo.reactionsBy(viewerId, ids)]);
    const countsByShare = groupBy(counts, (r) => r.shareId);
    const myReaction = new Map(mine.map((r) => [r.shareId, r.emoji]));

    return rows.map(({ share, owner }) => ({
      id: share.id,
      owner,
      emoji: share.emoji,
      name: share.name,
      occurredAt: share.occurredAt.toISOString(),
      reactions: (countsByShare.get(share.id) ?? []).map(({ emoji, count }) => ({ emoji, count })),
      myReaction: myReaction.get(share.id) ?? null,
    }));
  }
}
