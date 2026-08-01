import { Router } from "express";
import {
  registerEmailPassword,
  loginEmailPassword,
  createGuest,
  refresh,
  logout,
  me,
  updateMe,
  uploadAvatar,
} from "../controllers/auth.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { validate } from "../middleware/validate.middleware.js";
import { z } from "zod";
import { authLimiter } from "../middleware/rateLimit.middleware.js";
import { uploadImage } from "../middleware/upload.middleware.js";

const router = Router();

// Built-in email/password auth (manual JWT flow).
router.post(
  "/register",
  authLimiter,
  validate(
    z.object({
      email: z.string().email("Invalid email address"),
      password: z.string().min(6, "Password must be at least 6 characters"),
      name: z.string().min(1).max(60),
      username: z
        .string()
        .min(3)
        .max(24)
        .regex(/^[a-zA-Z0-9_]+$/, "Username may only contain letters, numbers and underscores"),
    }),
  ),
  registerEmailPassword,
);
router.post(
  "/login",
  authLimiter,
  validate(z.object({ email: z.string().email(), password: z.string().min(1) })),
  loginEmailPassword,
);
router.post("/guest", authLimiter, createGuest);

// Refresh-token rotation + logout revocation.
router.post(
  "/refresh",
  authLimiter,
  validate(z.object({ refreshToken: z.string().min(20) })),
  refresh,
);
router.post(
  "/logout",
  requireAuth,
  validate(z.object({ refreshToken: z.string().min(20).optional() })),
  logout,
);

router.get("/me", requireAuth, me);
router.patch(
  "/me",
  requireAuth,
  validate(
    z
      .object({
        name: z.string().min(1).max(60).optional(),
        username: z
          .string()
          .min(3)
          .max(24)
          .regex(/^[a-zA-Z0-9_]+$/, "Invalid username")
          .optional(),
        bio: z.string().max(160).optional(),
        location: z.string().max(120).optional(),
        link: z.string().max(200).optional(),
        avatar: z.string().max(500).optional(),
        coverUrl: z.string().max(500).optional(),
      })
      .strict(),
  ),
  updateMe,
);
router.post("/avatar", requireAuth, uploadImage.single("avatar"), uploadAvatar);

export default router;
