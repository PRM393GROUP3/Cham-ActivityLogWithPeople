import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { friendRoutes } from "./features/friends/friend.route";
import { feedRoutes, shareRoutes } from "./features/shares/share.route";
import { authRoutes, meRoutes } from "./features/users/user.route";
import { errorHandler, notFoundHandler } from "./middleware/error.middleware";
import type { AppEnv } from "./shared/types/env";

const app = new Hono<AppEnv>();

app.use(logger());
app.use("/api/*", (c, next) => cors({ origin: c.env.CORS_ORIGIN })(c, next));

app.get("/health", (c) => c.json({ status: "ok" }));
app.route("/api/auth", authRoutes);
app.route("/api/me", meRoutes);
app.route("/api/friends", friendRoutes);
app.route("/api/shares", shareRoutes);
app.route("/api/feed", feedRoutes);

app.onError(errorHandler);
app.notFound(notFoundHandler);

export default app;
