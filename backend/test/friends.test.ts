import { describe, expect, it } from "vitest";
import { api, befriend, json, register } from "./helpers";

describe("friends", () => {
  it("adds a mutual friend by invite code, idempotently", async () => {
    const [a, b] = [await register("A"), await register("B")];

    expect((await befriend(a, b)).status).toBe(201);
    expect((await befriend(a, b)).status).toBe(200);
    expect((await befriend(b, a)).status).toBe(200);

    expect((await json(await api("/friends", { token: a.token }))).map((f: { id: string }) => f.id)).toEqual([b.id]);
    expect((await json(await api("/friends", { token: b.token }))).map((f: { id: string }) => f.id)).toEqual([a.id]);
  });

  it("accepts a lowercase code with spaces", async () => {
    const [a, b] = [await register(), await register()];
    const code = `${b.inviteCode.slice(0, 5)} ${b.inviteCode.slice(5)}`.toLowerCase();
    const res = await api("/friends", { method: "POST", token: a.token, body: JSON.stringify({ inviteCode: code }) });
    expect(res.status).toBe(201);
  });

  it("rejects self, unknown and rotated codes", async () => {
    const [a, b] = [await register(), await register()];
    expect((await befriend(a, a)).status).toBe(400);

    const unknown = await api("/friends", { method: "POST", token: a.token, body: '{"inviteCode":"ZZZZZZZZZZ"}' });
    expect(unknown.status).toBe(404);

    await api("/me/invite-code", { method: "POST", token: b.token });
    expect((await befriend(a, b)).status).toBe(404);
  });

  it("removes the friendship in both directions", async () => {
    const [a, b] = [await register(), await register()];
    await befriend(a, b);

    expect((await api(`/friends/${b.id}`, { method: "DELETE", token: a.token })).status).toBe(204);
    expect(await json(await api("/friends", { token: b.token }))).toEqual([]);
    expect((await api(`/friends/${b.id}`, { method: "DELETE", token: a.token })).status).toBe(404);
  });
});
