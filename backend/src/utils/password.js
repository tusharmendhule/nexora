import crypto from "crypto";

const ITERATIONS = 100_000;
const KEY_LEN = 64;

/** Hash a plaintext password with a random salt (scrypt). */
export function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString("hex");
  const hash = crypto
    .scryptSync(password, salt, KEY_LEN, { N: 16384, r: 8, p: 1 })
    .toString("hex");
  return `${salt}:${hash}`;
}

/** Verify a plaintext password against a stored `salt:hash` string. */
export function verifyPassword(password, stored) {
  if (!stored || !stored.includes(":")) return false;
  const [salt, hash] = stored.split(":");
  const candidate = crypto
    .scryptSync(password, salt, KEY_LEN, { N: 16384, r: 8, p: 1 })
    .toString("hex");
  const a = Buffer.from(hash, "hex");
  const b = Buffer.from(candidate, "hex");
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}
