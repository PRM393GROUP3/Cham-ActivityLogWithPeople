import { Hono } from "hono";
import { KvCache } from "../../infrastructure/cache/kv-cache";
import { createDb } from "../../infrastructure/db/client";
import { getTodoRoom } from "../../infrastructure/realtime/realtime";
import type { AppEnv } from "../../shared/types/env";
import { validate } from "../../shared/utils/validator";
import { TodoRepository } from "./todo.repository";
import { createTodoSchema, todoIdParamSchema, updateTodoSchema } from "./todo.schema";
import { TodoService } from "./todo.service";

export const todoRoutes = new Hono<AppEnv>()
  .use(async (c, next) => {
    const service = new TodoService(
      new TodoRepository(createDb(c.env.DB)),
      new KvCache(c.env.CACHE),
      // Broadcast in the background so the HTTP response isn't blocked on it.
      (event) => c.executionCtx.waitUntil(getTodoRoom(c.env).broadcast(event)),
    );
    c.set("todoService", service);
    await next();
  })

  // WebSocket: clients receive TodoEvent JSON messages on every change.
  .get("/ws", (c) => getTodoRoom(c.env).fetch(c.req.raw))

  .get("/", async (c) => c.json({ data: await c.var.todoService.list() }))

  .get("/:id", validate("param", todoIdParamSchema), async (c) =>
    c.json({ data: await c.var.todoService.get(c.req.valid("param").id) }),
  )

  .post("/", validate("json", createTodoSchema), async (c) =>
    c.json({ data: await c.var.todoService.create(c.req.valid("json")) }, 201),
  )

  .patch("/:id", validate("param", todoIdParamSchema), validate("json", updateTodoSchema), async (c) =>
    c.json({ data: await c.var.todoService.update(c.req.valid("param").id, c.req.valid("json")) }),
  )

  .delete("/:id", validate("param", todoIdParamSchema), async (c) => {
    await c.var.todoService.remove(c.req.valid("param").id);
    return c.body(null, 204);
  });
