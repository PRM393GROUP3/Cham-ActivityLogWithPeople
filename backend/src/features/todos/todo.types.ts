import type { todos } from "../../infrastructure/db/schema";

export type TodoRow = typeof todos.$inferSelect;
export type NewTodoRow = typeof todos.$inferInsert;

/** Shape returned to clients (dates as ISO strings). */
export type TodoDto = {
  id: string;
  title: string;
  completed: boolean;
  createdAt: string;
  updatedAt: string;
};

export type TodoEvent =
  | { type: "todo.created"; todo: TodoDto }
  | { type: "todo.updated"; todo: TodoDto }
  | { type: "todo.deleted"; id: string };
