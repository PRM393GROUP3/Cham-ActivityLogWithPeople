import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { errorHandler, notFoundHandler } from "./middleware/error.middleware";
import type { AppEnv } from "./shared/types/env";

const app = new Hono<AppEnv>();

app.use(logger());
app.use("/api/*", (c, next) => cors({ origin: c.env.CORS_ORIGIN })(c, next));

app.get("/health", (c) => c.json({ status: "ok" }));

app.onError(errorHandler);
app.notFound(notFoundHandler);

export default app;
