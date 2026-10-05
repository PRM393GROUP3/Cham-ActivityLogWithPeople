import { describe, expect, it } from "vitest";
import { api, json, register } from "./helpers";

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
});
