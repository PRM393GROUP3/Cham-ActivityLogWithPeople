/**
 * Thin wrapper over an R2 bucket so features depend on "put/get/delete an object" rather than on
 * the R2 API. Objects are written once under a fresh key and never overwritten, so readers can
 * cache them forever.
 */
export class ObjectStorage {
  constructor(private readonly bucket: R2Bucket) {}

  async put(key: string, body: ArrayBuffer | Uint8Array, contentType: string): Promise<void> {
    await this.bucket.put(key, body, { httpMetadata: { contentType } });
  }

  get(key: string): Promise<R2ObjectBody | null> {
    return this.bucket.get(key);
  }

  async delete(key: string): Promise<void> {
    await this.bucket.delete(key);
  }
}

/** Response for a stored object: immutable caching (keys are never reused) and no MIME sniffing. */
export const objectResponse = (object: R2ObjectBody): Response =>
  new Response(object.body, {
    headers: {
      "Content-Type": object.httpMetadata?.contentType ?? "application/octet-stream",
      "Content-Length": String(object.size),
      "Cache-Control": "public, max-age=31536000, immutable",
      ETag: object.httpEtag,
      "X-Content-Type-Options": "nosniff",
    },
  });
