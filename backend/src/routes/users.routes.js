import { Router } from "express";
import {
  searchAll,
  explore,
  getReels,
  getUserProfile,
  toggleFollow,
  listFollowers,
  listFollowing,
  suggestUsers,
  toggleBlock,
  listBlocked,
} from "../controllers/users.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.get("/search", requireAuth, searchAll);
router.get("/explore", requireAuth, explore);
router.get("/reels", requireAuth, getReels);
router.get("/suggestions", requireAuth, suggestUsers);
router.get("/blocked", requireAuth, listBlocked);
router.get("/:id/followers", requireAuth, listFollowers);
router.get("/:id/following", requireAuth, listFollowing);
router.post("/:id/block", requireAuth, toggleBlock);
router.get("/:id", requireAuth, getUserProfile);
router.post("/:id/follow", requireAuth, toggleFollow);

export default router;
