import type { PublicUserDto } from "../users/user.types";

export type FriendDto = PublicUserDto & {
  /** When the friendship was created. */
  since: string;
};
