/**
 * Events are only hints ("something changed, refetch it"), never data: the client reloads
 * through the REST API, which applies the permission checks.
 */
export type RealtimeEvent =
  | { type: "share.upserted"; id: string } // a share became visible to you or was updated
  | { type: "share.removed"; id: string } // a share was deleted or you lost access to it
  | { type: "reaction.changed"; shareId: string } // someone reacted to one of your shares
  | { type: "friends.changed" };

export type Notify = (userIds: Iterable<string>, event: RealtimeEvent) => void;

export const getUserRoom = (env: Env, userId: string) =>
  env.USER_ROOM.get(env.USER_ROOM.idFromName(userId));

/** Fans an event out to each user's room in the background so the HTTP response isn't blocked. */
export const createNotifier =
  (env: Env, ctx: Pick<ExecutionContext, "waitUntil">): Notify =>
  (userIds, event) => {
    const sends = [...new Set(userIds)].map((id) => getUserRoom(env, id).send(event));
    if (sends.length) ctx.waitUntil(Promise.allSettled(sends));
  };
