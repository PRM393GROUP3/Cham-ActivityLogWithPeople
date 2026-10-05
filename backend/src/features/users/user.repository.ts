import { eq } from "drizzle-orm";
import type { Database } from "../../infrastructure/db/client";
import { users } from "../../infrastructure/db/schema";
import type { NewUserRow, UserRow } from "./user.types";

export class UserRepository {
  constructor(private readonly db: Database) {}

  findById(id: string): Promise<UserRow | undefined> {
    return this.db.select().from(users).where(eq(users.id, id)).get();
  }

  async create(data: NewUserRow): Promise<UserRow> {
    const [row] = await this.db.insert(users).values(data).returning();
    return row!;
  }

  async update(id: string, data: Partial<NewUserRow>): Promise<UserRow | undefined> {
    const [row] = await this.db.update(users).set(data).where(eq(users.id, id)).returning();
    return row;
  }
}
