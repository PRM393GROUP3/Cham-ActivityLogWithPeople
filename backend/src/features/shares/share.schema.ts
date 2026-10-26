import { z } from "zod";

/** Facebook-style reaction set (SOC-05). Fixed so clients can render them as a picker. */
export const REACTIONS = ["👍", "❤️", "🥰", "😆", "😮", "😢", "😡"] as const;

export const shareIdParamSchema = z.object({
  // The client's local record id (UUID), reused as the share id for idempotent retries.
  id: z.uuid(),
});

/**
 * Making a record Public. Strict: an unknown field such as the removed `targetIds` is rejected,
 * so an outdated client can't believe it limited the audience while the share goes to all friends.
 */
export const upsertShareSchema = z.strictObject({
  emoji: z.string().trim().min(1).max(64),
  name: z.string().trim().min(1).max(50),
  /** Original time of the log entry, kept even when sent late from the offline queue. */
  occurredAt: z.iso.datetime({ offset: true }).transform((v) => new Date(v)),
});

export const reactSchema = z.object({
  emoji: z.enum(REACTIONS),
});

export const pageQuerySchema = z.object({
  /** Opaque value from the previous page's `nextCursor`. */
  cursor: z
    .string()
    .regex(/^\d+_[\w-]+$/)
    .optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export type UpsertShareInput = z.infer<typeof upsertShareSchema>;
export type PageQuery = z.infer<typeof pageQuerySchema>;
