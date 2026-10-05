import { z } from "zod";

export const addFriendSchema = z.object({
  // Codes are uppercase; accept lowercase/spaces from manual entry.
  inviteCode: z
    .string()
    .transform((v) => v.replace(/\s/g, "").toUpperCase())
    .pipe(z.string().min(1).max(32)),
});

export const friendIdParamSchema = z.object({
  userId: z.string().min(1),
});

export type AddFriendInput = z.infer<typeof addFriendSchema>;
