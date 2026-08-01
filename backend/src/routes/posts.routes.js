import { Router } from "express";
import multer from "multer";
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

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post("/", requireAuth, upload.array("media", 10), createPost);
router.get("/saved", requireAuth, getSavedPosts);
router.get("/user/:userId", requireAuth, listPostsByUser);
router.get("/:id", requireAuth, getPost);
router.delete("/:id", requireAuth, deletePost);
router.post("/:id/like", requireAuth, toggleLike);
router.post("/:id/bookmark", requireAuth, toggleBookmark);
router.get("/:id/comments", requireAuth, getComments);
router.post("/:id/comments", requireAuth, addComment);

export default router;
