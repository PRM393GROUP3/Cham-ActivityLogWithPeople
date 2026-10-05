import { z } from "zod";

const displayName = z.string().trim().min(1).max(50);

export const registerSchema = z.object({ displayName });

export const updateMeSchema = z.object({ displayName });

export type RegisterInput = z.infer<typeof registerSchema>;
export type UpdateMeInput = z.infer<typeof updateMeSchema>;
