import { Hono, type Context } from "hono";
import { createDb } from "../../infrastructure/db/client";
import { createNotifier } from "../../infrastructure/realtime/realtime";
import { requireAuth } from "../../middleware/auth.middleware";
import type { AppEnv } from "../../shared/types/env";
import { validate } from "../../shared/utils/validator";
import { ShareRepository } from "./share.repository";
import { pageQuerySchema, reactSchema, shareIdParamSchema, upsertShareSchema } from "./share.schema";
import { ShareService } from "./share.service";

const shareService = (c: Context<AppEnv>) =>
  new ShareService(new ShareRepository(createDb(c.env.DB)), createNotifier(c.env, c.executionCtx));

/** Shares you own. */
export const shareRoutes = new Hono<AppEnv>()
  .use(requireAuth)

  .get("/", validate("query", pageQuerySchema), async (c) => {
    const { items, nextCursor } = await shareService(c).listOwned(c.var.user.id, c.req.valid("query"));
    return c.json({ data: items, nextCursor });
  })

  .get("/:id", validate("param", shareIdParamSchema), async (c) =>
    c.json({ data: await shareService(c).getOwned(c.var.user.id, c.req.valid("param").id) }),
  )

  // `:id` is the local record id: PUT is idempotent, so the offline queue can retry freely.
  .put("/:id", validate("param", shareIdParamSchema), validate("json", upsertShareSchema), async (c) => {
    const { share, created } = await shareService(c).upsert(
      c.var.user.id,
      c.req.valid("param").id,
      c.req.valid("json"),
    );
    return c.json({ data: share }, created ? 201 : 200);
  })

  .delete("/:id", validate("param", shareIdParamSchema), async (c) => {
    await shareService(c).remove(c.var.user.id, c.req.valid("param").id);
    return c.body(null, 204);
  });

/** Friends' shares visible to you, and your reactions on them. */
export const feedRoutes = new Hono<AppEnv>()
  .use(requireAuth)

  .get("/", validate("query", pageQuerySchema), async (c) => {
    const { items, nextCursor } = await shareService(c).feed(c.var.user.id, c.req.valid("query"));
    return c.json({ data: items, nextCursor });
  })

  .get("/:id", validate("param", shareIdParamSchema), async (c) =>
    c.json({ data: await shareService(c).getFeedItem(c.var.user.id, c.req.valid("param").id) }),
  )

  .put("/:id/reaction", validate("param", shareIdParamSchema), validate("json", reactSchema), async (c) =>
    c.json({
      data: await shareService(c).react(c.var.user.id, c.req.valid("param").id, c.req.valid("json").emoji),
    }),
  )

  .delete("/:id/reaction", validate("param", shareIdParamSchema), async (c) => {
    await shareService(c).unreact(c.var.user.id, c.req.valid("param").id);
    return c.body(null, 204);
  });
