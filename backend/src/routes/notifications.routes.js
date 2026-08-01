import { Router } from "express";
import {
  listNotifications,
  markRead,
  markAllRead,
} from "../controllers/notifications.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.get("/", requireAuth, listNotifications);
router.post("/read-all", requireAuth, markAllRead);
router.post("/:id/read", requireAuth, markRead);

export default router;
