import { describe, expect, it } from "vitest";
import { api, befriend, feedIds, json, register, share } from "./helpers";

/** Owner with three friends, plus a stranger who is nobody's friend. */
const setup = async () => {
  const [owner, b, c, d, stranger] = await Promise.all(["Owner", "B", "C", "D", "Stranger"].map((n) => register(n)));
  for (const f of [b!, c!, d!]) await befriend(owner!, f);
  return { owner: owner!, b: b!, c: c!, d: d!, stranger: stranger! };
};

describe("sharing & visibility", () => {
  it("broadcasts to all friends by default and keeps the original occurredAt (AC-05, AC-06)", async () => {
    const { owner, b, c, stranger } = await setup();
    const id = crypto.randomUUID();

    const res = await share(owner, id, { occurredAt: "2026-09-30T23:15:00+07:00" });
    expect(res.status).toBe(201);
    expect(await json(res)).toMatchObject({ audience: "all", occurredAt: "2026-09-30T16:15:00.000Z" });

    expect(await feedIds(b)).toEqual([id]);
    expect(await feedIds(c)).toEqual([id]);
    expect(await feedIds(stranger)).toEqual([]);
    expect(await feedIds(owner)).toEqual([]); // own shares live under /shares, not the feed
    expect((await api(`/feed/${id}`, { token: stranger.token })).status).toBe(404);
  });

  it("re-sending the same record never duplicates it (AC-05)", async () => {
    const { owner, b } = await setup();
    const id = crypto.randomUUID();

    expect((await share(owner, id)).status).toBe(201);
    expect((await share(owner, id)).status).toBe(200);
    expect((await share(owner, id)).status).toBe(200);

    expect(await feedIds(b)).toEqual([id]);
    expect(await json(await api("/shares", { token: owner.token }))).toHaveLength(1);
  });

  it("multicasts to targets only, follows target changes, and falls back to broadcast (AC-06)", async () => {
    const { owner, b, c, d } = await setup();
    const id = crypto.randomUUID();

    await share(owner, id, { targetIds: [b.id] });
    expect(await feedIds(b)).toEqual([id]);
    expect(await feedIds(c)).toEqual([]);

    const changed = await json(await share(owner, id, { targetIds: [c.id, d.id] }));
    expect(changed.audience).toBe("targets");
    expect([...changed.targetIds].sort()).toEqual([c.id, d.id].sort());
    expect(await feedIds(b)).toEqual([]);
    expect(await feedIds(c)).toEqual([id]);

    await share(owner, id, { targetIds: [] });
    for (const v of [b, c, d]) expect(await feedIds(v)).toEqual([id]);
  });

  it("ignores non-friend targets without falling back to broadcast", async () => {
    const { owner, b, stranger } = await setup();
    const id = crypto.randomUUID();

    const created = await json(await share(owner, id, { targetIds: [stranger.id] }));
    expect(created).toMatchObject({ audience: "targets", targetIds: [] });
    expect(await feedIds(b)).toEqual([]);
    expect(await feedIds(stranger)).toEqual([]);
  });

  it("refuses to overwrite another user's share id", async () => {
    const { owner, b } = await setup();
    const id = crypto.randomUUID();
    await share(owner, id);
    expect((await share(b, id)).status).toBe(409);
    expect((await api(`/shares/${id}`, { method: "DELETE", token: b.token })).status).toBe(404);
  });

  it("deleting revokes the share for everyone and is safe to retry (BR-03)", async () => {
    const { owner, b } = await setup();
    const id = crypto.randomUUID();
    await share(owner, id);

    expect((await api(`/shares/${id}`, { method: "DELETE", token: owner.token })).status).toBe(204);
    expect((await api(`/shares/${id}`, { method: "DELETE", token: owner.token })).status).toBe(204);
    expect(await feedIds(b)).toEqual([]);
    expect((await api(`/shares/${id}`, { token: owner.token })).status).toBe(404);
  });

  it("unfriending revokes access both ways, and re-friending doesn't restore old targets", async () => {
    const { owner, b } = await setup();
    const [broadcast, targeted, fromB] = [crypto.randomUUID(), crypto.randomUUID(), crypto.randomUUID()];
    await share(owner, broadcast);
    await share(owner, targeted, { targetIds: [b.id] });
    await share(b, fromB);

    await api(`/friends/${owner.id}`, { method: "DELETE", token: b.token });
    expect(await feedIds(b)).toEqual([]);
    expect(await feedIds(owner)).toEqual([]);

    await befriend(owner, b);
    expect(await feedIds(b)).toEqual([broadcast]);
    expect(await feedIds(owner)).toEqual([fromB]);
  });

  it("pages the feed newest-first by occurredAt", async () => {
    const { owner, b } = await setup();
    const ids: string[] = [];
    for (let day = 1; day <= 5; day++) {
      const id = crypto.randomUUID();
      ids.unshift(id);
      await share(owner, id, { occurredAt: `2026-10-0${day}T08:00:00Z` });
    }

    const page1 = (await (await api("/feed?limit=3", { token: b.token })).json()) as {
      data: { id: string }[];
      nextCursor: string;
    };
    expect(page1.data.map((s) => s.id)).toEqual(ids.slice(0, 3));

    const page2 = (await (await api(`/feed?limit=3&cursor=${page1.nextCursor}`, { token: b.token })).json()) as {
      data: { id: string }[];
      nextCursor: string | null;
    };
    expect(page2.data.map((s) => s.id)).toEqual(ids.slice(3));
    expect(page2.nextCursor).toBeNull();
  });
});

describe("reactions", () => {
  it("lets viewers react once (replaceable) and shows details to the owner (AC-04)", async () => {
    const { owner, b, c } = await setup();
    const id = crypto.randomUUID();
    await share(owner, id);

    const react = (u: typeof b, emoji: string) =>
      api(`/feed/${id}/reaction`, { method: "PUT", token: u.token, body: JSON.stringify({ emoji }) });

    expect((await json(await react(b, "😂"))).myReaction).toBe("😂");
    await react(b, "❤️");
    const item = await json(await react(c, "❤️"));
    expect(item.reactions).toEqual([{ emoji: "❤️", count: 2 }]);

    const own = await json(await api(`/shares/${id}`, { token: owner.token }));
    expect(own.reactions.map((r: { user: { id: string } }) => r.user.id).sort()).toEqual([b.id, c.id].sort());

    expect((await api(`/feed/${id}/reaction`, { method: "DELETE", token: b.token })).status).toBe(204);
    expect((await json(await api(`/feed/${id}`, { token: c.token }))).reactions).toEqual([{ emoji: "❤️", count: 1 }]);
  });

  it("rejects unsupported emoji, non-viewers and the owner", async () => {
    const { owner, b, stranger } = await setup();
    const id = crypto.randomUUID();
    await share(owner, id);
    const react = (token: string, emoji = "❤️") =>
      api(`/feed/${id}/reaction`, { method: "PUT", token, body: JSON.stringify({ emoji }) });

    expect((await react(b.token, "🍕")).status).toBe(400);
    expect((await react(stranger.token)).status).toBe(404);
    expect((await react(owner.token)).status).toBe(403);
  });

  it("drops reactions of viewers who lose access via target change", async () => {
    const { owner, b, c } = await setup();
    const id = crypto.randomUUID();
    await share(owner, id);
    await api(`/feed/${id}/reaction`, { method: "PUT", token: b.token, body: '{"emoji":"🔥"}' });

    await share(owner, id, { targetIds: [c.id] });
    expect((await json(await api(`/shares/${id}`, { token: owner.token }))).reactions).toEqual([]);
  });
});
