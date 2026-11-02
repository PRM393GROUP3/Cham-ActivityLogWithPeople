import type { ObjectStorage } from "../../infrastructure/storage/object-storage";
import type { ImageFormat } from "../../shared/utils/image";

export const MAX_AVATAR_BYTES = 2 * 1024 * 1024;

/** Path the avatar image is served from (resolve it against the API's origin). */
export const avatarUrl = (key: string | null): string | null => (key ? `/api/avatars/${key}` : null);

/** Keys are `<userId>/<uuid>.<ext>`: a new upload gets a new key, so old URLs stay cacheable. */
export class AvatarStorage {
  constructor(private readonly storage: ObjectStorage) {}

  async save(userId: string, bytes: Uint8Array, format: ImageFormat): Promise<string> {
    const key = `${userId}/${crypto.randomUUID()}.${format.ext}`;
    await this.storage.put(key, bytes, format.contentType);
    return key;
  }

  get(key: string) {
    return this.storage.get(key);
  }

  delete(key: string): Promise<void> {
    return this.storage.delete(key);
  }
}
