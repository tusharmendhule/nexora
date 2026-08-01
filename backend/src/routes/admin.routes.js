import { Router } from "express";
import {
  getAdminStats,
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
router.get("/users", listUsers);
router.patch(
  "/users/:id/role",
  validate(z.object({ role: z.enum(["user", "moderator", "admin"]) })),
  updateUserRole,
);
router.post("/users/:id/ban", toggleUserBan);

export default router;
