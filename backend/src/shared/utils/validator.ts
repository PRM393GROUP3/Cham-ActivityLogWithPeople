import { zValidator } from "@hono/zod-validator";
import type { ValidationTargets } from "hono";
import type { ZodType } from "zod";
import { ValidationError } from "../errors/app-error";

/** zValidator that throws our ValidationError so every 400 has the same JSON shape. */
export const validate = <T extends ZodType, Target extends keyof ValidationTargets>(
  target: Target,
  schema: T,
) =>
  zValidator(target, schema, (result) => {
    if (!result.success) throw new ValidationError(result.error.issues);
  });
