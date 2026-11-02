import { describe, expect, it } from "vitest";
import { addFriend, api, befriend, json, register } from "./helpers";

describe("friends", () => {
  it("adds a mutual friend by username, idempotently", async () => {
    const [a, b] = [await register("A"), await register("B")];

    expect((await befriend(a, b)).status).toBe(201);
    expect((await befriend(a, b)).status).toBe(200);
    expect((await befriend(b, a)).status).toBe(200);

    expect((await json(await api("/friends", { token: a.token }))).map((f: { id: string }) => f.id)).toEqual([b.id]);
    expect((await json(await api("/friends", { token: b.token }))).map((f: { id: string }) => f.id)).toEqual([a.id]);
  });

  it("accepts an uppercase username with '@' and spaces around it", async () => {
    const [a, b] = [await register(), await register()];
    expect((await addFriend(a, ` @${b.username.toUpperCase()} `)).status).toBe(201);
  });

  it("rejects self, unknown, renamed-away and malformed usernames", async () => {
    const [a, b] = [await register(), await register()];
    expect((await befriend(a, a)).status).toBe(400);

    const unknown = await addFriend(a, "nobody_here");
    expect(unknown.status).toBe(404);
    expect((await unknown.json()) as object).toMatchObject({ error: { code: "USER_NOT_FOUND" } });

    await api("/me", { method: "PATCH", token: b.token, body: JSON.stringify({ username: `${b.username}_2` }) });
    expect((await befriend(a, b)).status).toBe(404);
    expect((await addFriend(a, "a b")).status).toBe(400);
  });

  it("removes the friendship in both directions", async () => {
    const [a, b] = [await register(), await register()];
    await befriend(a, b);

    expect((await api(`/friends/${b.id}`, { method: "DELETE", token: a.token })).status).toBe(204);
    expect(await json(await api("/friends", { token: b.token }))).toEqual([]);
    expect((await api(`/friends/${b.id}`, { method: "DELETE", token: a.token })).status).toBe(404);
  });
});
