import { Router } from "express";
import {
  recomputeTrust,
  verifyClaim,
  getTrustOverview,
} from "../controllers/trust.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.post("/recompute", requireAuth, recomputeTrust);
router.get("/verify", requireAuth, verifyClaim);
router.get("/overview", requireAuth, getTrustOverview);

export default router;
