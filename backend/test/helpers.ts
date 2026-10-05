import { exports } from "cloudflare:workers";

export type TestUser = { id: string; token: string; inviteCode: string; displayName: string };

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

export const register = async (displayName = "User"): Promise<TestUser> => {
  const res = await api("/auth/register", { method: "POST", body: JSON.stringify({ displayName }) });
  const { user, token } = await json<{ user: { id: string; inviteCode: string }; token: string }>(res);
  return { id: user.id, inviteCode: user.inviteCode, token, displayName };
};

export const befriend = (a: TestUser, b: TestUser) =>
  api("/friends", { method: "POST", token: a.token, body: JSON.stringify({ inviteCode: b.inviteCode }) });
