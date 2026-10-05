import { NotFoundError } from "../../shared/errors/app-error";
import { generateInviteCode, generateToken, hashToken } from "../../shared/utils/crypto";
import type { UserRepository } from "./user.repository";
import type { RegisterInput, UpdateMeInput } from "./user.schema";
import type { MeDto, UserRow } from "./user.types";

const toMeDto = (row: UserRow): MeDto => ({
  id: row.id,
  displayName: row.displayName,
  inviteCode: row.inviteCode,
  createdAt: row.createdAt.toISOString(),
});

export class UserService {
  constructor(private readonly repo: UserRepository) {}

  /** Creates an anonymous account. The token is returned only here; the client must keep it. */
  async register(input: RegisterInput): Promise<{ user: MeDto; token: string }> {
    const token = generateToken();
    const now = new Date();
    const row = await this.repo.create({
      id: crypto.randomUUID(),
      displayName: input.displayName,
      tokenHash: await hashToken(token),
      inviteCode: generateInviteCode(),
      createdAt: now,
      updatedAt: now,
    });
    return { user: toMeDto(row), token };
  }

  async get(id: string): Promise<MeDto> {
    const row = await this.repo.findById(id);
    if (!row) throw new NotFoundError("User", id);
    return toMeDto(row);
  }

  async update(id: string, input: UpdateMeInput): Promise<MeDto> {
    return this.save(id, { displayName: input.displayName });
  }

  /** Invalidates the old QR: anyone holding the previous code can no longer add you. */
  async rotateInviteCode(id: string): Promise<MeDto> {
    return this.save(id, { inviteCode: generateInviteCode() });
  }

  private async save(id: string, data: Partial<UserRow>): Promise<MeDto> {
    const row = await this.repo.update(id, { ...data, updatedAt: new Date() });
    if (!row) throw new NotFoundError("User", id);
    return toMeDto(row);
  }
}
