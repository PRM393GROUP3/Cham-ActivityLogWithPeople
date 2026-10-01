import { exports } from "cloudflare:workers";
import { describe, expect, it } from "vitest";

const api = (path: string, init?: RequestInit) =>
  exports.default.fetch(`http://localhost/api/todos${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...init?.headers },
  });

describe("todos API", () => {
  it("creates, lists, updates and deletes a todo", async () => {
    const created = await api("", { method: "POST", body: JSON.stringify({ title: "Buy milk" }) });
    expect(created.status).toBe(201);
    const { data: todo } = await created.json<{ data: { id: string; completed: boolean } }>();
    expect(todo.completed).toBe(false);

    const list = await (await api("")).json<{ data: unknown[] }>();
    expect(list.data).toHaveLength(1);

    const updated = await api(`/${todo.id}`, { method: "PATCH", body: JSON.stringify({ completed: true }) });
    expect((await updated.json<{ data: { completed: boolean } }>()).data.completed).toBe(true);

    expect((await api(`/${todo.id}`, { method: "DELETE" })).status).toBe(204);
    expect((await api(`/${todo.id}`)).status).toBe(404);
  });

  it("rejects an empty title", async () => {
    const res = await api("", { method: "POST", body: JSON.stringify({ title: "  " }) });
    expect(res.status).toBe(400);
    expect((await res.json<{ error: { code: string } }>()).error.code).toBe("VALIDATION_ERROR");
  });
});
