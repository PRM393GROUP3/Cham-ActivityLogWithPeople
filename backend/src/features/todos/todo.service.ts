import type { KvCache } from "../../infrastructure/cache/kv-cache";
import { NotFoundError } from "../../shared/errors/app-error";
import type { TodoRepository } from "./todo.repository";
import type { CreateTodoInput, UpdateTodoInput } from "./todo.schema";
import type { TodoDto, TodoEvent, TodoRow } from "./todo.types";

const LIST_CACHE_KEY = "todos:list";

const toDto = (row: TodoRow): TodoDto => ({
  id: row.id,
  title: row.title,
  completed: row.completed,
  createdAt: row.createdAt.toISOString(),
  updatedAt: row.updatedAt.toISOString(),
});

export class TodoService {
  constructor(
    private readonly repo: TodoRepository,
    private readonly cache: KvCache,
    private readonly publish: (event: TodoEvent) => void,
  ) {}

  async list(): Promise<TodoDto[]> {
    const cached = await this.cache.get<TodoDto[]>(LIST_CACHE_KEY);
    if (cached) return cached;

    const todos = (await this.repo.findAll()).map(toDto);
    await this.cache.set(LIST_CACHE_KEY, todos, 60);
    return todos;
  }

  async get(id: string): Promise<TodoDto> {
    const row = await this.repo.findById(id);
    if (!row) throw new NotFoundError("Todo", id);
    return toDto(row);
  }

  async create(input: CreateTodoInput): Promise<TodoDto> {
    const now = new Date();
    const todo = toDto(
      await this.repo.create({ id: crypto.randomUUID(), title: input.title, createdAt: now, updatedAt: now }),
    );
    await this.afterWrite({ type: "todo.created", todo });
    return todo;
  }

  async update(id: string, input: UpdateTodoInput): Promise<TodoDto> {
    const row = await this.repo.update(id, { ...input, updatedAt: new Date() });
    if (!row) throw new NotFoundError("Todo", id);
    const todo = toDto(row);
    await this.afterWrite({ type: "todo.updated", todo });
    return todo;
  }

  async remove(id: string): Promise<void> {
    if (!(await this.repo.delete(id))) throw new NotFoundError("Todo", id);
    await this.afterWrite({ type: "todo.deleted", id });
  }

  private async afterWrite(event: TodoEvent) {
    await this.cache.delete(LIST_CACHE_KEY);
    this.publish(event);
  }
}
