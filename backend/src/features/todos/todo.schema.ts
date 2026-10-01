import { z } from "zod";

export const todoIdParamSchema = z.object({
  id: z.string().min(1),
});

export const createTodoSchema = z.object({
  title: z.string().trim().min(1).max(200),
});

export const updateTodoSchema = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    completed: z.boolean().optional(),
  })
  .refine((v) => v.title !== undefined || v.completed !== undefined, {
    message: "At least one of 'title' or 'completed' is required",
  });

export type CreateTodoInput = z.infer<typeof createTodoSchema>;
export type UpdateTodoInput = z.infer<typeof updateTodoSchema>;
