import jwt from "jsonwebtoken";
import { env } from "../config/env.js";
import { User } from "../models/User.js";

/**
 * Verify the `Authorization: Bearer <access-token>` header and attach the
 * authenticated user to `req.user`.
 *
 * Nexora uses manual JWT auth only: a short-lived access token (15m) for
 * every request, with refresh-token rotation for session renewal.
 */
export async function requireAuth(req, res, next) {
  const header = req.headers.authorization ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "Missing bearer token" });

  try {
    const payload = jwt.verify(token, env.jwtSecret);
    if (payload.type !== "access") {
      return res.status(401).json({ error: "Invalid token type" });
    }
    const user = await User.findById(payload.sub);
    if (!user) return res.status(401).json({ error: "User not found" });
    req.user = user;
    return next();
  } catch {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

/** Restrict a route to moderators or admins. */
export function requireModerator(req, res, next) {
  if (!["moderator", "admin"].includes(req.user?.role)) {
    return res.status(403).json({ error: "Moderator access required" });
  }
  return next();
}

/** Restrict a route to admins. */
export function requireAdmin(req, res, next) {
  if (req.user?.role !== "admin") {
    return res.status(403).json({ error: "Admin access required" });
  }
  return next();
}
