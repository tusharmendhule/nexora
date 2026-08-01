import crypto from "crypto";
import jwt from "jsonwebtoken";
import { env } from "../config/env.js";
import { User } from "../models/User.js";
import { RefreshToken } from "../models/RefreshToken.js";
import { hashPassword, verifyPassword } from "../utils/password.js";

const ACCESS_TOKEN_TTL = "15m";
const REFRESH_TOKEN_TTL_DAYS = 30;

/** Sign a short-lived access token (used on every API call). */
const signAccessToken = (userId) =>
  jwt.sign({ sub: userId.toString(), type: "access" }, env.jwtSecret, {
    expiresIn: ACCESS_TOKEN_TTL,
  });

/** Generate a cryptographically-random refresh token and persist its hash. */
async function issueRefreshToken(user, req) {
  const raw = crypto.randomBytes(48).toString("hex");
  const tokenHash = crypto.createHash("sha256").update(raw).digest("hex");
  await RefreshToken.create({
    user: user._id,
    tokenHash,
    expiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_DAYS * 24 * 3600 * 1000),
    userAgent: req.headers["user-agent"]?.slice(0, 200) ?? "",
    ip: req.ip ?? "",
  });
  return raw;
}

/** Shape the Mongo user document for API responses. */
export function toUserResponse(user) {
  return {
    id: user._id.toString(),
    email: user.email,
    name: user.name,
    username: user.username ?? "",
    avatar: user.avatar ?? "",
    coverUrl: user.coverUrl ?? "",
    bio: user.bio ?? "",
    location: user.location ?? "",
    link: user.link ?? "",
    role: user.role ?? "user",
    trustScore: user.trustScore ?? 50,
    trustLabel: user.trustLabel ?? "Watch",
    isVerified: user.isVerified ?? false,
    followers: user.followersCount ?? 0,
    following: user.followingCount ?? 0,
  };
}

/** Build the auth payload (access + refresh + user). */
async function authPayload(user, req) {
  const refreshToken = await issueRefreshToken(user, req);
  return {
    token: signAccessToken(user._id),
    refreshToken,
    user: toUserResponse(user),
  };
}

const handleAuthError = (res, err, next) => {
  if (err.code === 11000) return res.status(409).json({ error: "Account already exists" });
  return next(err);
};

/* ── Email / password (manual JWT auth) ─────────────────────────────── */

export async function registerEmailPassword(req, res, next) {
  try {
    const { email, password, name, username } = req.body;
    if (!email || !password || !name || !username) {
      return res.status(400).json({ error: "email, password, name and username are required" });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: "Password must be at least 6 characters" });
    }
    const cleanUsername = username.replace(/^@/, "").trim();
    if (!/^[a-zA-Z0-9_]{3,24}$/.test(cleanUsername)) {
      return res.status(400).json({ error: "Username must be 3-24 letters, numbers or underscores" });
    }

    const existing = await User.findOne({
      $or: [{ email: email.toLowerCase() }, { username: cleanUsername }],
    });
    if (existing) return res.status(409).json({ error: "Account already exists" });

    const user = await User.create({
      email: email.toLowerCase(),
      passwordHash: hashPassword(password),
      name,
      username: cleanUsername,
    });

    res.status(201).json(await authPayload(user, req));
  } catch (err) {
    handleAuthError(res, err, next);
  }
}

export async function loginEmailPassword(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "email and password are required" });
    }
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user || !user.passwordHash || !verifyPassword(password, user.passwordHash)) {
      return res.status(401).json({ error: "Invalid email or password" });
    }
    res.json(await authPayload(user, req));
  } catch (err) {
    next(err);
  }
}

/** Create an anonymous guest account (demo mode / quick preview). */
export async function createGuest(req, res, next) {
  try {
    const suffix = Math.random().toString(36).slice(2, 8);
    const user = await User.create({
      email: `guest_${suffix}@nexora.local`,
      passwordHash: hashPassword(`guest-${suffix}-${Date.now()}`),
      name: `Guest ${suffix.slice(0, 4).toUpperCase()}`,
      username: `guest_${suffix}`,
    });
    res.status(201).json(await authPayload(user, req));
  } catch (err) {
    next(err);
  }
}

/* ── Refresh tokens (rotation + revocation) ─────────────────────────── */

/**
 * Exchange a valid refresh token for a new access token + rotated refresh
 * token. Rotation means the presented token is revoked and a new one issued,
 * so a stolen token can only be used once.
 */
export async function refresh(req, res, next) {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: "refreshToken required" });
    }
    const tokenHash = crypto.createHash("sha256").update(refreshToken).digest("hex");
    const stored = await RefreshToken.findOne({ tokenHash });
    if (!stored || stored.revokedAt) {
      return res.status(401).json({ error: "Invalid refresh token" });
    }
    if (stored.expiresAt < new Date()) {
      await RefreshToken.deleteOne({ _id: stored._id });
      return res.status(401).json({ error: "Refresh token expired" });
    }

    const user = await User.findById(stored.user);
    if (!user) return res.status(401).json({ error: "User not found" });

    // Rotate: revoke this token, issue a fresh pair.
    const raw = crypto.randomBytes(48).toString("hex");
    const nextHash = crypto.createHash("sha256").update(raw).digest("hex");
    await RefreshToken.create({
      user: user._id,
      tokenHash: nextHash,
      expiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_DAYS * 24 * 3600 * 1000),
      userAgent: req.headers["user-agent"]?.slice(0, 200) ?? "",
      ip: req.ip ?? "",
    });
    stored.revokedAt = new Date();
    stored.replacedBy = nextHash;
    await stored.save();

    res.json({
      token: signAccessToken(user._id),
      refreshToken: raw,
      user: toUserResponse(user),
    });
  } catch (err) {
    next(err);
  }
}

/** Revoke the presented refresh token (logout). */
export async function logout(req, res, next) {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      const tokenHash = crypto.createHash("sha256").update(refreshToken).digest("hex");
      await RefreshToken.updateOne(
        { tokenHash, revokedAt: null },
        { revokedAt: new Date() },
      );
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

/** Return the profile of the authenticated user. */
export async function me(req, res) {
  res.json({ user: toUserResponse(req.user) });
}

/** Upload a new avatar image to Cloudinary and update the profile. */
export async function uploadAvatar(req, res, next) {
  try {
    const file = req.file;
    if (!file) return res.status(400).json({ error: "avatar image required" });
    const { media } = await import("../services/cloudinary.service.js");
    const uploaded = await media.upload({ buffer: file.buffer, folder: "nexora/avatars" });
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { avatar: uploaded.url },
      { new: true },
    );
    res.json({ user: toUserResponse(user) });
  } catch (err) {
    next(err);
  }
}

/** Update the authenticated user's profile. */
export async function updateMe(req, res, next) {
  try {
    const { name, username, bio, location, link, avatar, coverUrl } = req.body;
    const updates = {};
    if (name !== undefined) updates.name = name.trim();
    if (bio !== undefined) updates.bio = bio.trim().slice(0, 160);
    if (location !== undefined) updates.location = location.trim();
    if (link !== undefined) updates.link = link.trim();
    if (avatar !== undefined) updates.avatar = avatar;
    if (coverUrl !== undefined) updates.coverUrl = coverUrl;
    if (username !== undefined) {
      const clean = username.replace(/^@/, "").trim();
      if (!/^[a-zA-Z0-9_]{3,24}$/.test(clean)) {
        return res.status(400).json({ error: "Invalid username" });
      }
      const taken = await User.findOne({ username: clean, _id: { $ne: req.user._id } });
      if (taken) return res.status(409).json({ error: "Username already taken" });
      updates.username = clean;
    }

    const user = await User.findByIdAndUpdate(req.user._id, updates, { new: true });
    res.json({ user: toUserResponse(user) });
  } catch (err) {
    next(err);
  }
}
