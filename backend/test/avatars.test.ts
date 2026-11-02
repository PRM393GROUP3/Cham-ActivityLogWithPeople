import { env } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import { api, befriend, json, register, type TestUser } from "./helpers";

const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3, 4]);
const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 5, 6, 7, 8]);

const upload = (u: TestUser, body: BodyInit, contentType = "image/png") =>
  api("/me/avatar", { method: "PUT", token: u.token, body, headers: { "Content-Type": contentType } });

/** GET an `avatarUrl` (it already starts with `/api`), without a token. */
const fetchAvatar = (avatarUrl: string) => api(avatarUrl.replace(/^\/api/, ""));

/** `avatarUrl` is `/api/avatars/<key>`; the key is what R2 stores. */
const keyOf = (avatarUrl: string) => avatarUrl.replace("/api/avatars/", "");

describe("avatar images (R2)", () => {
  it("uploads an image, serves it publicly, and shows it to friends", async () => {
    const a = await register("A");
    const b = await register("B");
    const me = await json(await upload(a, png));
    expect(me.avatarUrl).toMatch(new RegExp(`^/api/avatars/${a.id}/[0-9a-f-]{36}\.png$`));

    const res = await fetchAvatar(me.avatarUrl);
    expect(res.status).toBe(200);
    expect(res.headers.get("Content-Type")).toBe("image/png");
    expect(res.headers.get("Cache-Control")).toContain("immutable");
    expect(new Uint8Array(await res.arrayBuffer())).toEqual(png);

    await befriend(b, a);
    expect((await json(await api("/friends", { token: b.token })))[0].avatarUrl).toBe(me.avatarUrl);
  });

  it("an image and an emoji replace each other, and replaced images are deleted from R2", async () => {
    const u = await register("U");
    const patch = (body: object) => api("/me", { method: "PATCH", token: u.token, body: JSON.stringify(body) });
    await patch({ avatarEmoji: "🐼" });

    const first = await json(await upload(u, png));
    expect(first).toMatchObject({ avatarEmoji: null });
    const second = await json(await upload(u, jpeg, "application/octet-stream"));
    expect(second.avatarUrl).toMatch(/\.jpg$/);
    expect(await env.AVATARS.get(keyOf(first.avatarUrl))).toBeNull();

    const emoji = await json(await patch({ avatarEmoji: "🦊" }));
    expect(emoji).toMatchObject({ avatarEmoji: "🦊", avatarUrl: null });
    expect(await env.AVATARS.get(keyOf(second.avatarUrl))).toBeNull();

    const third = await json(await upload(u, png));
    expect((await json(await patch({ displayName: "Renamed" }))).avatarUrl).toBe(third.avatarUrl);
    const removed = await json(await api("/me/avatar", { method: "DELETE", token: u.token }));
    expect(removed).toMatchObject({ avatarEmoji: null, avatarUrl: null });
    expect(await env.AVATARS.get(keyOf(third.avatarUrl))).toBeNull();
  });

  it("rejects non-images, oversized files and missing tokens", async () => {
    const u = await register("V");
    expect((await upload(u, "<html><script>alert(1)</script>", "image/png")).status).toBe(415);
    expect((await upload(u, new Uint8Array())).status).toBe(415);
    const big = new Uint8Array(2 * 1024 * 1024 + 1);
    big.set(png);
    expect((await upload(u, big)).status).toBe(413);
    expect((await api("/me/avatar", { method: "PUT", body: png })).status).toBe(401);
    expect((await json(await api("/me", { token: u.token }))).avatarUrl).toBeNull();
  });

  it("404s unknown avatars and malformed keys", async () => {
    const u = await register("W");
    expect((await fetchAvatar(`/api/avatars/${u.id}/${crypto.randomUUID()}.png`)).status).toBe(404);
    expect((await fetchAvatar(`/api/avatars/${u.id}/..%2Fsecret.png`)).status).toBe(400);
  });
});
