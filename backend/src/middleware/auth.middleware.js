import jwt from "jsonwebtoken";
import { env } from "../config/env.js";
import { User } from "../models/User.js";
import { isFirebaseConfigured } from "../services/firebase.service.js";

/**
 * Verify the `Authorization: Bearer <token>` header and attach the
 * authenticated user to `req.user`.
 *
 * Nexora signs its own JWTs with `JWT_SECRET` for every auth method
 * (email/password, guest, Firebase exchange). Firebase ID tokens are also
 * accepted when Firebase Admin is configured, as a fallback.
 */
export async function requireAuth(req, res, next) {
  const header = req.headers.authorization ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "Missing bearer token" });

  try {
    // 1) Local Nexora JWT.
    try {
      const payload = jwt.verify(token, env.jwtSecret);
      const user = await User.findById(payload.sub);
      if (user) {
        req.user = user;
        return next();
      }
    } catch {
      /* not a local JWT — fall through to Firebase */
    }

    // 2) Firebase ID token (optional).
    if (await isFirebaseConfigured()) {
      const { getAuth } = await import("firebase-admin");
      const { getFirebaseApp } = await import("../services/firebase.service.js");
      const app = await getFirebaseApp();
      const decoded = await getAuth(app).verifyIdToken(token);

      let user = await User.findOne({ firebaseUid: decoded.uid });
      if (!user) {
        user = await User.create({
          firebaseUid: decoded.uid,
          email: decoded.email ?? `${decoded.uid}@nexora.local`,
          name: decoded.name ?? "Nexora user",
          avatar: decoded.picture ?? "",
        });
      }
      req.user = user;
      return next();
    }

    return res.status(401).json({ error: "Invalid or expired token" });
  } catch {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

/** Restrict a route to admins. */
export function requireAdmin(req, res, next) {
  if (req.user?.role !== "admin") {
    return res.status(403).json({ error: "Admin access required" });
  }
  return next();
}
