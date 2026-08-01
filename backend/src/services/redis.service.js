import { createClient } from "redis";
import { env } from "../config/env.js";

let client = null;
let connected = false;

async function getClient() {
  if (!env.redisUrl) return null;
  if (connected) return client;
  if (!client) {
    client = createClient({
      url: env.redisUrl,
      socket: {
        connectTimeout: 2000,
        reconnectStrategy: false, // fail fast when Redis is down — caching is optional
      },
    });
    client.on("error", (err) => {
      console.warn("[redis] connection error:", err.message);
      connected = false;
    });
  }
  try {
    await client.connect();
    connected = true;
  } catch (err) {
    console.warn("[redis] unavailable — caching disabled:", err.message);
    return null;
  }
  return client;
}

export const cache = {
  /** Get a cached value (JSON), or null on miss / when Redis is down. */
  async get(key) {
    const c = await getClient();
    if (!c) return null;
    const raw = await c.get(key).catch(() => null);
    return raw ? JSON.parse(raw) : null;
  },

  /** Cache a value with an expiry in seconds. */
  async set(key, value, ttlSeconds = 300) {
    const c = await getClient();
    if (!c) return;
    await c.setEx(key, ttlSeconds, JSON.stringify(value)).catch(() => {});
  },

  async del(key) {
    const c = await getClient();
    if (!c) return;
    await c.del(key).catch(() => {});
  },

  /** Delete every key matching a glob pattern (e.g. `feed:*`). */
  async delPattern(pattern) {
    const c = await getClient();
    if (!c) return;
    const keys = await c.keys(pattern).catch(() => []);
    if (keys.length) await c.del(keys).catch(() => {});
  },
};
