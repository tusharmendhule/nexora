import { Router } from "express";
import {
  searchAll,
  explore,
  getReels,
  getUserProfile,
  toggleFollow,
  suggestUsers,
} from "../controllers/users.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.get("/search", requireAuth, searchAll);
router.get("/explore", requireAuth, explore);
router.get("/reels", requireAuth, getReels);
router.get("/suggestions", requireAuth, suggestUsers);
router.get("/:id", requireAuth, getUserProfile);
router.post("/:id/follow", requireAuth, toggleFollow);

export default router;
