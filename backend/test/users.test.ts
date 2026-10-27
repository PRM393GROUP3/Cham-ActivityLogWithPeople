import { describe, expect, it } from "vitest";
import { api, befriend, feedIds, json, register, share } from "./helpers";

describe("auth & me", () => {
  it("registers an anonymous user and authenticates with the returned token", async () => {
    const u = await register("An");
    const me = await json(await api("/me", { token: u.token }));
    expect(me).toMatchObject({ id: u.id, displayName: "An", inviteCode: u.inviteCode });

    const renamed = await json(
      await api("/me", { method: "PATCH", token: u.token, body: JSON.stringify({ displayName: "An Nguyễn" }) }),
    );
    expect(renamed.displayName).toBe("An Nguyễn");
  });

  it("rejects missing or wrong tokens", async () => {
    expect((await api("/me")).status).toBe(401);
    expect((await api("/me", { token: "nope" })).status).toBe(401);
  });

  it("rejects an empty display name", async () => {
    const res = await api("/auth/register", { method: "POST", body: JSON.stringify({ displayName: "  " }) });
    expect(res.status).toBe(400);
  });

  it("sets a name and an emoji avatar at registration or later; null clears the avatar", async () => {
    const res = await api("/auth/register", {
      method: "POST",
      body: JSON.stringify({ displayName: "Bình", avatarEmoji: "🐼" }),
    });
    const { user, token } = await json(res);
    expect(user).toMatchObject({ displayName: "Bình", avatarEmoji: "🐼" });

    const patch = (body: object) => api("/me", { method: "PATCH", token, body: JSON.stringify(body) });
    expect(await json(await patch({ avatarEmoji: "👩‍💻" }))).toMatchObject({ displayName: "Bình", avatarEmoji: "👩‍💻" });
    expect((await json(await patch({ avatarEmoji: "👍🏽" }))).avatarEmoji).toBe("👍🏽");
    expect((await json(await patch({ avatarEmoji: "🇻🇳" }))).avatarEmoji).toBe("🇻🇳");
    expect((await json(await patch({ displayName: "Bình An" }))).avatarEmoji).toBe("🇻🇳");
    expect((await json(await patch({ avatarEmoji: null }))).avatarEmoji).toBeNull();
    expect((await register("NoAvatar")).id).toBeTruthy();
  });

  it("rejects avatars that are not an emoji, and empty updates", async () => {
    const u = await register("C");
    const patch = (body: object) => api("/me", { method: "PATCH", token: u.token, body: JSON.stringify(body) });
    for (const avatarEmoji of ["a", "abc", "1", "#", "😀 hi", "", "😀😀", "😀".repeat(9)]) {
      expect((await patch({ avatarEmoji })).status, avatarEmoji).toBe(400);
    }
    expect((await patch({})).status).toBe(400);
  });

  it("friends and feed show the friend's avatar emoji", async () => {
    const a = await register("A");
    const b = await register("B");
    await api("/me", { method: "PATCH", token: a.token, body: JSON.stringify({ avatarEmoji: "🦊" }) });
    await befriend(b, a);
    expect((await json(await api("/friends", { token: b.token })))[0]).toMatchObject({ displayName: "A", avatarEmoji: "🦊" });

    const id = crypto.randomUUID();
    await share(a, id);
    expect(await feedIds(b)).toEqual([id]);
    expect((await json(await api(`/feed/${id}`, { token: b.token }))).owner).toMatchObject({ avatarEmoji: "🦊" });
  });
});
