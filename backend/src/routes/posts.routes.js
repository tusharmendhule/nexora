import { Router } from "express";
import {
  createPost,
  getPost,
  deletePost,
  listPostsByUser,
  toggleLike,
  toggleBookmark,
  getSavedPosts,
  getComments,
  addComment,
} from "../controllers/posts.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { writeLimiter } from "../middleware/rateLimit.middleware.js";
import { validate } from "../middleware/validate.middleware.js";
import { uploadMedia } from "../middleware/upload.middleware.js";
import { z } from "zod";

const router = Router();

router.post(
  "/",
  requireAuth,
  writeLimiter,
  uploadMedia.array("media", 10),
  validate(
    z.object({
      caption: z.string().max(2200).default(""),
      hashtags: z.array(z.string().max(50)).max(20).optional(),
      mentions: z.array(z.string().max(50)).max(20).optional(),
      location: z.string().max(120).optional(),
    }),
  ),
  createPost,
);
router.get("/saved", requireAuth, getSavedPosts);
router.get("/user/:userId", requireAuth, listPostsByUser);
router.get("/:id", requireAuth, getPost);
router.delete("/:id", requireAuth, deletePost);
router.post("/:id/like", requireAuth, writeLimiter, toggleLike);
router.post("/:id/bookmark", requireAuth, writeLimiter, toggleBookmark);
router.get("/:id/comments", requireAuth, getComments);
router.post(
  "/:id/comments",
  requireAuth,
  writeLimiter,
  validate(z.object({ text: z.string().min(1).max(1000) })),
  addComment,
);

export default router;
