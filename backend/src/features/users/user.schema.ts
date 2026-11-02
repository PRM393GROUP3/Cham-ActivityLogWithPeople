import { z } from "zod";

const displayName = z.string().trim().min(1).max(50);

/** 3–20 chars of `a-z 0-9 . _`, case-insensitive (stored lowercase); no leading/trailing or doubled dot. */
const username = z
  .string()
  .trim()
  .toLowerCase()
  .regex(/^(?!\.)(?!.*\.\.)[a-z0-9._]{3,20}(?<!\.)$/, {
    message: "username must be 3-20 characters of a-z, 0-9, '.' or '_'",
  });

const graphemes = new Intl.Segmenter(undefined, { granularity: "grapheme" });

/**
 * Exactly one emoji as the user sees it — including multi-codepoint ones such as 👩‍💻, 👍🏽 or 🇻🇳
 * (one grapheme cluster that is pictographic or a flag). null clears the avatar.
 */
const avatarEmoji = z
  .string()
  .trim()
  .max(32)
  .refine(
    (v) => [...graphemes.segment(v)].length === 1 && /\p{Extended_Pictographic}|\p{Regional_Indicator}/u.test(v),
    { message: "avatarEmoji must be exactly one emoji" },
  );

export const registerSchema = z.object({ displayName, avatarEmoji: avatarEmoji.nullish() });

export const updateMeSchema = z
  .object({
    displayName: displayName.optional(),
    username: username.optional(),
    avatarEmoji: avatarEmoji.nullable().optional(),
  })
  .refine((v) => v.displayName !== undefined || v.username !== undefined || v.avatarEmoji !== undefined, {
    message: "At least one of 'displayName', 'username' or 'avatarEmoji' is required",
  });

export const avatarParamSchema = z.object({
  userId: z.uuid(),
  file: z.string().regex(/^[0-9a-f-]{36}\.(jpg|png|webp)$/),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type UpdateMeInput = z.infer<typeof updateMeSchema>;
