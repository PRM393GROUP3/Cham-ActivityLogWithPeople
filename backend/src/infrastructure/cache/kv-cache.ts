/**
 * Thin JSON cache over Workers KV. KV is eventually consistent (writes can take
 * up to ~60s to propagate globally), so only cache data that tolerates staleness
 * and always invalidate on writes.
 */
export class KvCache {
  constructor(private readonly kv: KVNamespace) {}

  get<T>(key: string): Promise<T | null> {
    return this.kv.get<T>(key, "json");
  }

  async set(key: string, value: unknown, ttlSeconds = 300): Promise<void> {
    // KV's minimum TTL is 60 seconds.
    await this.kv.put(key, JSON.stringify(value), { expirationTtl: Math.max(60, ttlSeconds) });
  }

  delete(key: string): Promise<void> {
    return this.kv.delete(key);
  }
}
