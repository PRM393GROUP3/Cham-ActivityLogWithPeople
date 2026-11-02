import { AppError, ConflictError, NotFoundError } from "../../shared/errors/app-error";
import { generateToken, hashToken } from "../../shared/utils/crypto";
import { detectImageFormat } from "../../shared/utils/image";
import { avatarUrl, MAX_AVATAR_BYTES, type AvatarStorage } from "./avatar.storage";
import type { UserRepository } from "./user.repository";
import type { RegisterInput, UpdateMeInput } from "./user.schema";
import type { MeDto, PublicUserDto, PublicUserRow, UserRow } from "./user.types";

export const toPublicUserDto = (row: PublicUserRow): PublicUserDto => ({
  id: row.id,
  displayName: row.displayName,
  username: row.username,
  avatarEmoji: row.avatarEmoji,
  avatarUrl: avatarUrl(row.avatarKey),
});

const toMeDto = (row: UserRow): MeDto => ({
  ...toPublicUserDto(row),
  createdAt: row.createdAt.toISOString(),
});

export class UserService {
  constructor(
    private readonly repo: UserRepository,
    private readonly avatars: AvatarStorage,
  ) {}

  /** Creates an anonymous account. The token is returned only here; the client must keep it. */
  async register(input: RegisterInput): Promise<{ user: MeDto; token: string }> {
    const token = generateToken();
    const now = new Date();
    const row = await this.repo.create({
      id: crypto.randomUUID(),
      displayName: input.displayName,
      avatarEmoji: input.avatarEmoji ?? null,
      tokenHash: await hashToken(token),
      createdAt: now,
      updatedAt: now,
    });
    return { user: toMeDto(row), token };
  }

  async get(id: string): Promise<MeDto> {
    return toMeDto(await this.require(id));
  }

  /**
   * Setting `avatarEmoji` (or clearing it with null) also removes an uploaded avatar image.
   * A username someone else has is a 409 USERNAME_TAKEN.
   */
  async update(id: string, input: UpdateMeInput): Promise<MeDto> {
    if (input.username !== undefined) {
      const owner = await this.repo.findByUsername(input.username);
      if (owner && owner.id !== id) throw usernameTaken();
    }
    const profile = {
      ...(input.displayName !== undefined && { displayName: input.displayName }),
      ...(input.username !== undefined && { username: input.username }),
    };
    if (input.avatarEmoji === undefined) return this.save(id, profile);
    return this.replaceAvatar(id, { ...profile, avatarEmoji: input.avatarEmoji, avatarKey: null });
  }

  /** Stores a JPEG / PNG / WebP (≤ MAX_AVATAR_BYTES) as the avatar, replacing any emoji or older image. */
  async uploadAvatar(id: string, bytes: Uint8Array): Promise<MeDto> {
    if (bytes.byteLength > MAX_AVATAR_BYTES) throw avatarTooLarge();
    const format = detectImageFormat(bytes);
    if (!format) throw new AppError(415, "UNSUPPORTED_IMAGE", "Avatar must be a JPEG, PNG or WebP image");

    await this.require(id);
    const key = await this.avatars.save(id, bytes, format);
    return this.replaceAvatar(id, { avatarEmoji: null, avatarKey: key });
  }

  /** Back to the name's first letter. Idempotent. */
  async removeAvatar(id: string): Promise<MeDto> {
    return this.replaceAvatar(id, { avatarEmoji: null, avatarKey: null });
  }

  /** Saves the new avatar fields, then deletes the previous image (if it was replaced). */
  private async replaceAvatar(id: string, data: Partial<UserRow>): Promise<MeDto> {
    const previousKey = (await this.require(id)).avatarKey;
    const me = await this.save(id, data);
    if (previousKey && previousKey !== data.avatarKey) await this.avatars.delete(previousKey);
    return me;
  }

  private async require(id: string): Promise<UserRow> {
    const row = await this.repo.findById(id);
    if (!row) throw new NotFoundError("User", id);
    return row;
  }

  private async save(id: string, data: Partial<UserRow>): Promise<MeDto> {
    const row = await this.repo.update(id, { ...data, updatedAt: new Date() }).catch((e: unknown) => {
      // Lost a race for the same username between the check and the write.
      if (data.username && /UNIQUE constraint failed: users\.username/.test(String(e))) throw usernameTaken();
      throw e;
    });
    if (!row) throw new NotFoundError("User", id);
    return toMeDto(row);
  }
}

const usernameTaken = () => new AppError(409, "USERNAME_TAKEN", "This username is already taken");

export const avatarTooLarge = () =>
  new AppError(413, "AVATAR_TOO_LARGE", `Avatar must be at most ${MAX_AVATAR_BYTES / 1024 / 1024} MB`);
