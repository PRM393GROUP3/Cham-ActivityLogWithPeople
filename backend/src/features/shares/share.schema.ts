import { z } from "zod";

/** Supported reactions. Kept small and fixed so clients can render them as a picker. */
export const REACTIONS = ["❤️", "😂", "😮", "😢", "👍", "🔥"] as const;

export const shareIdParamSchema = z.object({
  // The client's local record id (UUID), reused as the share id for idempotent retries.
  id: z.uuid(),
});

export const upsertShareSchema = z.object({
  emoji: z.string().trim().min(1).max(64),
  name: z.string().trim().min(1).max(50),
  /** Original time of the log entry, kept even when sent late from the offline queue. */
  occurredAt: z.iso.datetime({ offset: true }).transform((v) => new Date(v)),
  /**
   * Omitted, null or [] → broadcast to all friends. Non-empty → only these friends (multicast).
   * Ids that aren't your friends are ignored. Max 90 keeps queries under D1's bound-parameter limit.
   */
  targetIds: z
    .array(z.string().min(1))
    .max(90)
    .nullish()
    .transform((ids) => (ids?.length ? [...new Set(ids)] : null)),
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
