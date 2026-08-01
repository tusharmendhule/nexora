import { Post } from "../models/Post.js";
import { TrustResult } from "../models/TrustResult.js";
import { Story } from "../models/Story.js";
import { cache } from "../services/redis.service.js";
import { shapePosts } from "./posts.controller.js";
import { getSettings } from "./admin.controller.js";

/** Build the home feed: visible posts with trust labels + user interaction flags. */
export async function getFeed(req, res, next) {
  try {
    const cacheKey = `feed:${req.user._id}:${req.query.cursor ?? "start"}`;
    const cached = await cache.get(cacheKey);
    if (cached) return res.json(cached);

    const limit = Math.min(Number(req.query.limit ?? 20), 50);
    const cursor = req.query.cursor ? new Date(req.query.cursor) : new Date();

    const posts = await Post.find({
      moderationStatus: "visible",
      createdAt: { $lt: cursor },
    })
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate("author", "name avatar username trustLabel trustScore isVerified")
      .lean();

    const trustResults = await TrustResult.find({
      post: { $in: posts.map((p) => p._id) },
    }).lean();
    const trustByPost = new Map(trustResults.map((t) => [t.post.toString(), t]));

    const userId = req.user._id.toString();
    const shaped = await shapePosts(
      posts.map((p) => ({ ...p, _doc: p })),
      userId,
    );
    const feed = shaped.map((p) => ({
      ...p,
      trust: trustByPost.get(p.id) ?? null,
    }));

    const body = {
      data: feed,
      nextCursor: feed.length === limit ? feed[feed.length - 1].createdAt : null,
    };
    await cache.set(cacheKey, body, 60);
    res.json(body);
  } catch (err) {
    next(err);
  }
}

/** Active (non-expired) stories from everyone, newest first. */
export async function getStories(req, res, next) {
  try {
    const stories = await Story.find({ expiresAt: { $gt: new Date() } })
      .sort({ createdAt: -1 })
      .limit(60)
      .populate("user", "name avatar username trustLabel trustScore isVerified")
      .lean();
    res.json({
      data: stories.map((s) => ({
        id: s._id.toString(),
        user: s.user,
        imageUrl: s.imageUrl,
        caption: s.caption ?? "",
        isMine: s.user?._id?.toString() === req.user._id.toString(),
      })),
    });
  } catch (err) {
    next(err);
  }
}

/** Create a story (image upload, expires in 24h). */
export async function createStory(req, res, next) {
  try {
    // Maintenance mode makes the platform read-only for members.
    const settings = await getSettings();
    if (settings.maintenanceMode && req.user.role !== "admin") {
      return res.status(503).json({
        error: "Nexora is in maintenance mode — stories are temporarily disabled.",
      });
    }
    const file = req.files?.[0] ?? req.file;
    if (!file) return res.status(400).json({ error: "story image required" });
    const uploaded = await mediaUpload(req, file);
    const story = await Story.create({
      user: req.user._id,
      imageUrl: uploaded.url,
      caption: req.body.caption ?? "",
      expiresAt: new Date(Date.now() + 24 * 3600 * 1000),
    });
    await cache.delPattern(`stories:*`);
    res.status(201).json({ story });
  } catch (err) {
    next(err);
  }
}

// local helper to avoid a circular import with cloudinary
async function mediaUpload(req, file) {
  const { media } = await import("../services/cloudinary.service.js");
  return media.upload({ buffer: file.buffer });
}
