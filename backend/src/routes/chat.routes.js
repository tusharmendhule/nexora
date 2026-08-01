import { Router } from "express";
import {
  listConversations,
  startConversation,
  getMessages,
  sendMessage,
} from "../controllers/chat.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.get("/", requireAuth, listConversations);
router.post("/", requireAuth, startConversation);
router.get("/:id/messages", requireAuth, getMessages);
router.post("/:id/messages", requireAuth, sendMessage);

export default router;
