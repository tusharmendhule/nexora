import { Router } from "express";
import { getFeed, getStories, createStory } from "../controllers/feed.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { writeLimiter } from "../middleware/rateLimit.middleware.js";
import { validate } from "../middleware/validate.middleware.js";
import { uploadImage } from "../middleware/upload.middleware.js";
import { z } from "zod";

const router = Router();

router.get("/", requireAuth, getFeed);
router.get("/stories", requireAuth, getStories);
router.post(
  "/stories",
  requireAuth,
  writeLimiter,
  uploadImage.single("image"),
  validate(z.object({ caption: z.string().max(200).optional() })),
  createStory,
);

export default router;
