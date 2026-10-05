import type { Notify } from "../../infrastructure/realtime/realtime";
import { AppError, NotFoundError } from "../../shared/errors/app-error";
import type { UserRepository } from "../users/user.repository";
import type { FriendRepository, FriendRow } from "./friend.repository";
import type { FriendDto } from "./friend.types";

const toDto = (row: FriendRow): FriendDto => ({
  id: row.id,
  displayName: row.displayName,
  since: row.since.toISOString(),
});

export class FriendService {
  constructor(
    private readonly repo: FriendRepository,
    private readonly users: UserRepository,
    private readonly notify: Notify,
  ) {}

  async list(userId: string): Promise<FriendDto[]> {
    return (await this.repo.list(userId)).map(toDto);
  }

  /** Scanning someone's QR makes you friends immediately (no request/accept step). */
  async addByInviteCode(userId: string, inviteCode: string): Promise<{ friend: FriendDto; created: boolean }> {
    const other = await this.users.findByInviteCode(inviteCode);
    if (!other) throw new AppError(404, "INVITE_NOT_FOUND", "Invite code is invalid or has been rotated");
    if (other.id === userId) throw new AppError(400, "CANNOT_FRIEND_SELF", "You can't add yourself as a friend");

    const existing = await this.repo.find(userId, other.id);
    if (existing) return { friend: toDto(existing), created: false };

    await this.repo.add(userId, other.id);
    this.notify([userId, other.id], { type: "friends.changed" });
    return { friend: toDto((await this.repo.find(userId, other.id))!), created: true };
  }

  /** Unfriending revokes both sides' access to each other's shares (see FriendRepository.remove). */
  async remove(userId: string, friendId: string): Promise<void> {
    if (!(await this.repo.remove(userId, friendId))) throw new NotFoundError("Friend", friendId);
    this.notify([userId, friendId], { type: "friends.changed" });
  }
}
