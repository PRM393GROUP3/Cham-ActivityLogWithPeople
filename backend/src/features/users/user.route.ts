import { Hono, type Context } from "hono";
import { createDb } from "../../infrastructure/db/client";
import { getUserRoom } from "../../infrastructure/realtime/realtime";
import { requireAuth } from "../../middleware/auth.middleware";
import type { AppEnv } from "../../shared/types/env";
import { validate } from "../../shared/utils/validator";
import { UserRepository } from "./user.repository";
import { registerSchema, updateMeSchema } from "./user.schema";
import { UserService } from "./user.service";

const userService = (c: Context<AppEnv>) => new UserService(new UserRepository(createDb(c.env.DB)));

/** Public: first launch of the app calls this once and stores the returned token. */
export const authRoutes = new Hono<AppEnv>().post("/register", validate("json", registerSchema), async (c) =>
  c.json({ data: await userService(c).register(c.req.valid("json")) }, 201),
);

export const meRoutes = new Hono<AppEnv>()
  .use(requireAuth)

  .get("/", async (c) => c.json({ data: await userService(c).get(c.var.user.id) }))

  .patch("/", validate("json", updateMeSchema), async (c) =>
    c.json({ data: await userService(c).update(c.var.user.id, c.req.valid("json")) }),
  )

  .post("/invite-code", async (c) => c.json({ data: await userService(c).rotateInviteCode(c.var.user.id) }))

  // WebSocket (`?token=` allowed): receives RealtimeEvent hints for the current user.
  .get("/ws", (c) => getUserRoom(c.env, c.var.user.id).fetch(c.req.raw));
