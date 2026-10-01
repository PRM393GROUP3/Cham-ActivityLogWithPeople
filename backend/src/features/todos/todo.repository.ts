import { desc, eq } from "drizzle-orm";
import type { Database } from "../../infrastructure/db/client";
import { todos } from "../../infrastructure/db/schema";
import type { NewTodoRow, TodoRow } from "./todo.types";

export class TodoRepository {
  constructor(private readonly db: Database) {}

  findAll(): Promise<TodoRow[]> {
    return this.db.select().from(todos).orderBy(desc(todos.createdAt));
  }

  findById(id: string): Promise<TodoRow | undefined> {
    return this.db.select().from(todos).where(eq(todos.id, id)).get();
  }

  async create(data: NewTodoRow): Promise<TodoRow> {
    const [row] = await this.db.insert(todos).values(data).returning();
    return row!;
  }

  async update(id: string, data: Partial<NewTodoRow>): Promise<TodoRow | undefined> {
    const [row] = await this.db.update(todos).set(data).where(eq(todos.id, id)).returning();
    return row;
  }

  async delete(id: string): Promise<boolean> {
    const rows = await this.db.delete(todos).where(eq(todos.id, id)).returning({ id: todos.id });
    return rows.length > 0;
  }
}
