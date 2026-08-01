import { Router } from "express";
import authRoutes from "./auth.routes.js";
import feedRoutes from "./feed.routes.js";
import postsRoutes from "./posts.routes.js";
import moderationRoutes from "./moderation.routes.js";
import trustRoutes from "./trust.routes.js";
import reportsRoutes from "./reports.routes.js";
import usersRoutes from "./users.routes.js";
import chatRoutes from "./chat.routes.js";
import notificationsRoutes from "./notifications.routes.js";
import adminRoutes from "./admin.routes.js";

const router = Router();

router.get("/health", (req, res) =>
  res.json({ status: "ok", service: "nexora-api", time: new Date().toISOString() }),
);

router.use("/auth", authRoutes);
router.use("/feed", feedRoutes);
router.use("/posts", postsRoutes);
router.use("/moderation", moderationRoutes);
router.use("/trust", trustRoutes);
router.use("/reports", reportsRoutes);
router.use("/users", usersRoutes);
router.use("/chat", chatRoutes);
router.use("/notifications", notificationsRoutes);
router.use("/admin", adminRoutes);

export default router;
