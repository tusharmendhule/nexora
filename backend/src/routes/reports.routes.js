import { Router } from "express";
import {
  createReport,
  listReports,
  getReport,
} from "../controllers/reports.controller.js";
import { requireAuth, requireModerator } from "../middleware/auth.middleware.js";

const router = Router();

router.post("/", requireAuth, createReport);

// Moderation console (list + detail) — moderators and admins only.
router.get("/", requireAuth, requireModerator, listReports);
router.get("/:id", requireAuth, requireModerator, getReport);

export default router;
