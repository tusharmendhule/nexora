import { Router } from "express";
import { createReport } from "../controllers/reports.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.post("/", requireAuth, createReport);

export default router;
