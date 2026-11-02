import { z } from "zod";
import { username } from "../users/user.schema";

export const addFriendSchema = z.object({
  // Typed by hand or read from the friend's QR; a leading '@' is fine.
  username: z
    .string()
    .transform((v) => v.trim().replace(/^@/, ""))
    .pipe(username),
});

export const friendIdParamSchema = z.object({
  userId: z.string().min(1),
});

export type AddFriendInput = z.infer<typeof addFriendSchema>;
