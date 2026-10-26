import { z } from "zod";

const displayName = z.string().trim().min(1).max(50);

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
  .object({ displayName: displayName.optional(), avatarEmoji: avatarEmoji.nullable().optional() })
  .refine((v) => v.displayName !== undefined || v.avatarEmoji !== undefined, {
    message: "At least one of 'displayName' or 'avatarEmoji' is required",
  });

export type RegisterInput = z.infer<typeof registerSchema>;
export type UpdateMeInput = z.infer<typeof updateMeSchema>;
