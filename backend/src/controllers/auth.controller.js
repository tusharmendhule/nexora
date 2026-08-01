import jwt from "jsonwebtoken";
import { env } from "../config/env.js";
import { User } from "../models/User.js";
import { verifyIdToken } from "../services/firebase.service.js";
import { hashPassword, verifyPassword } from "../utils/password.js";

const signToken = (userId) =>
  jwt.sign({ sub: userId.toString() }, env.jwtSecret, { expiresIn: "7d" });

/** Shape the Mongo user document for API responses. */
export function toUserResponse(user) {
  return {
    id: user._id.toString(),
    firebaseUid: user.firebaseUid ?? null,
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

const handleAuthError = (res, err, next) => {
  if (err.status === 503) return res.status(503).json({ error: err.message });
  if (err.code === 11000) return res.status(409).json({ error: "Account already exists" });
  return res.status(401).json({ error: "Invalid credentials" });
};

/* ── Email / password (built-in Nexora auth) ─────────────────────────── */

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

    res.status(201).json({ token: signToken(user._id), user: toUserResponse(user) });
  } catch (err) {
    next(err);
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
    res.json({ token: signToken(user._id), user: toUserResponse(user) });
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
    res.status(201).json({ token: signToken(user._id), user: toUserResponse(user) });
  } catch (err) {
    next(err);
  }
}

/* ── Firebase (optional legacy flow) ─────────────────────────────────── */

/**
 * Exchange a Firebase ID token for a Nexora JWT + profile.
 * Looks the user up by `firebaseUid`; creates the profile on first sign-in.
 */
export async function loginWithFirebase(req, res, next) {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ error: "idToken is required" });

    const decoded = await verifyIdToken(idToken);

    let user = await User.findOne({ firebaseUid: decoded.uid });
    if (!user) {
      user = await User.create({
        firebaseUid: decoded.uid,
        email: decoded.email ?? `${decoded.uid}@nexora.local`,
        name: decoded.name ?? "Nexora user",
        avatar: decoded.picture ?? "",
      });
    }

    res.json({ token: signToken(user._id), user: toUserResponse(user) });
  } catch (err) {
    handleAuthError(res, err, next);
  }
}

/**
 * Create a Nexora profile for a brand-new Firebase user (sign-up).
 * Requires a verified ID token plus the profile fields from the register form.
 */
export async function registerWithFirebase(req, res, next) {
  try {
    const { idToken, name, username } = req.body;
    if (!idToken) return res.status(400).json({ error: "idToken is required" });
    if (!name || !username) return res.status(400).json({ error: "name and username are required" });

    const decoded = await verifyIdToken(idToken);

    const existing = await User.findOne({
      $or: [{ firebaseUid: decoded.uid }, { username }],
    });
    if (existing) return res.status(409).json({ error: "Account already exists" });

    const user = await User.create({
      firebaseUid: decoded.uid,
      email: decoded.email ?? `${decoded.uid}@nexora.local`,
      name,
      username,
      avatar: decoded.picture ?? "",
    });

    res.status(201).json({ token: signToken(user._id), user: toUserResponse(user) });
  } catch (err) {
    handleAuthError(res, err, next);
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
