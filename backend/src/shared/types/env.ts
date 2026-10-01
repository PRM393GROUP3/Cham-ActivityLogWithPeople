import type { TodoService } from "../../features/todos/todo.service";

/** Hono generic for every route/middleware in the app. `Env` comes from `wrangler types`. */
export type AppEnv = {
  Bindings: Env;
  Variables: {
    todoService: TodoService;
  };
};
