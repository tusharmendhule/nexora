import { Router } from "express";
import {
  getAdminStats,
  getAdminSettings,
  updateAdminSettings,
  listUsers,
  updateUserRole,
  toggleUserBan,
} from "../controllers/admin.controller.js";
import { requireAuth, requireAdmin } from "../middleware/auth.middleware.js";
import { validate } from "../middleware/validate.middleware.js";
import { z } from "zod";

const router = Router();

router.use(requireAuth, requireAdmin);

router.get("/stats", getAdminStats);
router.get("/settings", getAdminSettings);
router.put(
  "/settings",
  validate(
    z.object({
      maintenanceMode: z.boolean().optional(),
      verifiedOnlyExplore: z.boolean().optional(),
      aiTriage: z.boolean().optional(),
    }),
  ),
  updateAdminSettings,
);
router.get("/users", listUsers);
router.patch(
  "/users/:id/role",
  validate(z.object({ role: z.enum(["user", "moderator", "admin"]) })),
  updateUserRole,
);
router.post("/users/:id/ban", toggleUserBan);

export default router;
