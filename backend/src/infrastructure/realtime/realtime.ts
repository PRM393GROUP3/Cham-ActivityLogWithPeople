/** All clients currently share a single room; split by user/list id once auth exists. */
const GLOBAL_ROOM = "global";

export const getTodoRoom = (env: Env) => env.TODO_ROOM.get(env.TODO_ROOM.idFromName(GLOBAL_ROOM));
