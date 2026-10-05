import { createMiddleware } from "hono/factory";
import { eq } from "drizzle-orm";
import { createDb } from "../infrastructure/db/client";
import { users } from "../infrastructure/db/schema";
import { UnauthorizedError } from "../shared/errors/app-error";
import type { AppEnv } from "../shared/types/env";
import { hashToken } from "../shared/utils/crypto";

/**
 * Resolves `Authorization: Bearer <token>` to the current user. Browsers can't set headers on a
 * WebSocket handshake, so WebSocket upgrades may pass the token as `?token=` instead.
 */
export const requireAuth = createMiddleware<AppEnv>(async (c, next) => {
  const header = c.req.header("Authorization");
  const token = header?.startsWith("Bearer ")
    ? header.slice("Bearer ".length).trim()
    : c.req.header("Upgrade") === "websocket"
      ? c.req.query("token")
      : undefined;
  if (!token) throw new UnauthorizedError();

  const user = await createDb(c.env.DB)
    .select({ id: users.id, displayName: users.displayName })
    .from(users)
    .where(eq(users.tokenHash, await hashToken(token)))
    .get();
  if (!user) throw new UnauthorizedError();

  c.set("user", user);
  await next();
});
