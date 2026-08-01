import { Router } from "express";
import { getQueue, takeAction } from "../controllers/moderation.controller.js";
import { getModerationStats } from "../controllers/admin.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

// Moderation is restricted to moderators and admins.
router.use(requireAuth, (req, res, next) => {
  if (!["moderator", "admin"].includes(req.user.role)) {
    return res.status(403).json({ error: "Moderator access required" });
  }
  next();
});

router.get("/queue", getQueue);
router.get("/stats", getModerationStats);
router.post("/action", takeAction);

export default router;
