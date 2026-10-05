import { Hono, type Context } from "hono";
import { createDb } from "../../infrastructure/db/client";
import { createNotifier } from "../../infrastructure/realtime/realtime";
import { requireAuth } from "../../middleware/auth.middleware";
import type { AppEnv } from "../../shared/types/env";
import { validate } from "../../shared/utils/validator";
import { UserRepository } from "../users/user.repository";
import { FriendRepository } from "./friend.repository";
import { addFriendSchema, friendIdParamSchema } from "./friend.schema";
import { FriendService } from "./friend.service";

const friendService = (c: Context<AppEnv>) => {
  const db = createDb(c.env.DB);
  return new FriendService(new FriendRepository(db), new UserRepository(db), createNotifier(c.env, c.executionCtx));
};

export const friendRoutes = new Hono<AppEnv>()
  .use(requireAuth)

  .get("/", async (c) => c.json({ data: await friendService(c).list(c.var.user.id) }))

  // Body is the invite code read from the other user's QR. 201 if new, 200 if already friends.
  .post("/", validate("json", addFriendSchema), async (c) => {
    const { friend, created } = await friendService(c).addByInviteCode(c.var.user.id, c.req.valid("json").inviteCode);
    return c.json({ data: friend }, created ? 201 : 200);
  })

  .delete("/:userId", validate("param", friendIdParamSchema), async (c) => {
    await friendService(c).remove(c.var.user.id, c.req.valid("param").userId);
    return c.body(null, 204);
  });
