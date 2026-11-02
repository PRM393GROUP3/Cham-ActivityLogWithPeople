import { Hono, type Context } from "hono";
import { bodyLimit } from "hono/body-limit";
import { createDb } from "../../infrastructure/db/client";
import { getUserRoom } from "../../infrastructure/realtime/realtime";
import { ObjectStorage, objectResponse } from "../../infrastructure/storage/object-storage";
import { requireAuth } from "../../middleware/auth.middleware";
import { NotFoundError } from "../../shared/errors/app-error";
import type { AppEnv } from "../../shared/types/env";
import { validate } from "../../shared/utils/validator";
import { AvatarStorage, MAX_AVATAR_BYTES } from "./avatar.storage";
import { UserRepository } from "./user.repository";
import { avatarParamSchema, registerSchema, updateMeSchema } from "./user.schema";
import { avatarTooLarge, UserService } from "./user.service";

const avatarStorage = (c: Context<AppEnv>) => new AvatarStorage(new ObjectStorage(c.env.AVATARS));

const userService = (c: Context<AppEnv>) =>
  new UserService(new UserRepository(createDb(c.env.DB)), avatarStorage(c));

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

  // Body is the raw image bytes (any Content-Type); the format is detected from the bytes.
  .put(
    "/avatar",
    bodyLimit({
      maxSize: MAX_AVATAR_BYTES,
      onError: () => {
        throw avatarTooLarge();
      },
    }),
    async (c) =>
      c.json({ data: await userService(c).uploadAvatar(c.var.user.id, new Uint8Array(await c.req.arrayBuffer())) }),
  )

  .delete("/avatar", async (c) => c.json({ data: await userService(c).removeAvatar(c.var.user.id) }))

  .post("/invite-code", async (c) => c.json({ data: await userService(c).rotateInviteCode(c.var.user.id) }))

  // WebSocket (`?token=` allowed): receives RealtimeEvent hints for the current user.
  .get("/ws", (c) => getUserRoom(c.env, c.var.user.id).fetch(c.req.raw));

/**
 * Public, so `<img src>` / Image.network work without a token. Keys are random UUIDs, only
 * handed out to people who can already see the user (friends, feed, reactions).
 */
export const avatarRoutes = new Hono<AppEnv>().get("/:userId/:file", validate("param", avatarParamSchema), async (c) => {
  const key = `${c.req.valid("param").userId}/${c.req.valid("param").file}`;
  const object = await avatarStorage(c).get(key);
  if (!object) throw new NotFoundError("Avatar", key);
  return objectResponse(object);
});
