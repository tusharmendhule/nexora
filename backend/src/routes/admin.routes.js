import { Router } from "express";
import { getAdminStats } from "../controllers/admin.controller.js";
import { requireAuth, requireAdmin } from "../middleware/auth.middleware.js";

const router = Router();

router.get("/stats", requireAuth, requireAdmin, getAdminStats);

export default router;
