import { exports } from "cloudflare:workers";

export type TestUser = { id: string; token: string; username: string; displayName: string };

export const api = (path: string, init: RequestInit & { token?: string } = {}) => {
  const { token, ...rest } = init;
  return exports.default.fetch(`http://localhost/api${path}`, {
    ...rest,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...rest.headers,
    },
  });
};

export const json = async <T = any>(res: Response) => ((await res.json()) as { data: T }).data;

/** A new user with a unique username (friends are added by it). */
export const register = async (displayName = "User"): Promise<TestUser> => {
  const res = await api("/auth/register", { method: "POST", body: JSON.stringify({ displayName }) });
  const { user, token } = await json<{ user: { id: string }; token: string }>(res);
  const username = `u_${user.id.replace(/-/g, "").slice(0, 16)}`;
  await api("/me", { method: "PATCH", token, body: JSON.stringify({ username }) });
  return { id: user.id, username, token, displayName };
};

export const addFriend = (a: TestUser, username: string) =>
  api("/friends", { method: "POST", token: a.token, body: JSON.stringify({ username }) });

export const befriend = (a: TestUser, b: TestUser) => addFriend(a, b.username);

export const share = (
  owner: TestUser,
  id: string,
  body: { occurredAt?: string; emoji?: string; name?: string } = {},
) =>
  api(`/shares/${id}`, {
    method: "PUT",
    token: owner.token,
    body: JSON.stringify({ emoji: "☕", name: "Cà phê", occurredAt: "2026-10-01T08:30:00.000Z", ...body }),
  });

export const feedIds = async (viewer: TestUser) =>
  (await json<{ id: string }[]>(await api("/feed", { token: viewer.token }))).map((s) => s.id);
