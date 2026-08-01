import { Router } from "express";
import {
  listConversations,
  startConversation,
  getMessages,
  sendMessage,
} from "../controllers/chat.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { validate } from "../middleware/validate.middleware.js";
import { uploadImage } from "../middleware/upload.middleware.js";
import { z } from "zod";

const router = Router();

router.get("/", requireAuth, listConversations);
router.post(
  "/",
  requireAuth,
  validate(z.object({ userId: z.string().min(1) })),
  startConversation,
);
router.get("/:id/messages", requireAuth, getMessages);
router.post(
  "/:id/messages",
  requireAuth,
  uploadImage.single("image"),
  sendMessage,
);

export default router;
