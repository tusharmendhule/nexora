import bcrypt from "bcryptjs";

const SALT_ROUNDS = 10;

/** Hash a plaintext password with bcrypt. */
export function hashPassword(password) {
  return bcrypt.hashSync(password, SALT_ROUNDS);
}

/** Verify a plaintext password against a stored bcrypt hash. */
export function verifyPassword(password, stored) {
  if (!stored || typeof stored !== "string") return false;
  try {
    return bcrypt.compareSync(password, stored);
  } catch {
    return false;
  }
}
