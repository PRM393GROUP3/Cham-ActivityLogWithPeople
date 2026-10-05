/** The authenticated caller, set by `requireAuth`. */
export type CurrentUser = { id: string; displayName: string };

/** Hono generic for every route/middleware in the app. `Env` comes from `wrangler types`. */
export type AppEnv = {
  Bindings: Env;
  Variables: {
    user: CurrentUser;
  };
};
