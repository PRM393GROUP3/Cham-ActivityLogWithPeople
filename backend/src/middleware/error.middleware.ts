import type { ErrorHandler, NotFoundHandler } from "hono";
import { HTTPException } from "hono/http-exception";
import { AppError } from "../shared/errors/app-error";

export const errorHandler: ErrorHandler = (err, c) => {
  if (err instanceof AppError) {
    return c.json({ error: { code: err.code, message: err.message, details: err.details } }, err.status);
  }
  if (err instanceof HTTPException) {
    return c.json({ error: { code: "HTTP_ERROR", message: err.message } }, err.status);
  }
  console.error(err);
  return c.json({ error: { code: "INTERNAL_ERROR", message: "Internal server error" } }, 500);
};

export const notFoundHandler: NotFoundHandler = (c) =>
  c.json({ error: { code: "NOT_FOUND", message: `Route ${c.req.method} ${c.req.path} not found` } }, 404);
