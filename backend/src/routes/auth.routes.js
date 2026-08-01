import { Router } from "express";
import multer from "multer";
import {
  loginWithFirebase,
  registerWithFirebase,
  registerEmailPassword,
  loginEmailPassword,
  createGuest,
  me,
  updateMe,
  uploadAvatar,
} from "../controllers/auth.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

// Built-in email/password auth (primary flow).
router.post("/register", registerEmailPassword);
router.post("/login", loginEmailPassword);
router.post("/guest", createGuest);

// Legacy Firebase ID-token exchange (kept for compatibility).
router.post("/firebase/register", registerWithFirebase);
router.post("/firebase/login", loginWithFirebase);

router.get("/me", requireAuth, me);
router.patch("/me", requireAuth, updateMe);
router.post("/avatar", requireAuth, upload.single("avatar"), uploadAvatar);

export default router;
