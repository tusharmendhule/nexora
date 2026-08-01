import { Router } from "express";
import multer from "multer";
import { getFeed, getStories, createStory } from "../controllers/feed.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.get("/", requireAuth, getFeed);
router.get("/stories", requireAuth, getStories);
router.post("/stories", requireAuth, upload.single("image"), createStory);

export default router;
