import { Post } from "../models/Post.js";
import { TrustResult } from "../models/TrustResult.js";
import { Comment } from "../models/Comment.js";
import { Like } from "../models/Like.js";
import { Bookmark } from "../models/Bookmark.js";
import { Notification } from "../models/Notification.js";
import { media } from "../services/cloudinary.service.js";
import { ai } from "../services/ai.service.js";
import { cache } from "../services/redis.service.js";
import { emitToUser } from "../services/socket.service.js";
import { recomputeUserTrust } from "../services/trust.service.js";

/** Coerce mention strings/usernames into valid User ObjectIds (drop invalid). */
async function resolveMentions(mentions) {
  if (!Array.isArray(mentions) || mentions.length === 0) return [];
  const { Types } = await import("mongoose");
  const { User } = await import("../models/User.js");
  const ids = [];
  for (const m of mentions.slice(0, 20)) {
    const raw = String(m ?? "").replace(/^@/, "").trim();
    if (!raw) continue;
    if (Types.ObjectId.isValid(raw)) {
      ids.push(new Types.ObjectId(raw));
      continue;
    }
    const user = await User.findOne({ username: raw }).select("_id");
    if (user) ids.push(user._id);
  }
  return ids;
}

/** Shape a single post document for API responses with author + interaction flags. */
export async function shapePost(post, currentUserId) {
  const doc = post._doc ?? post;
  const [isLiked, isBookmarked] = await Promise.all([
    currentUserId ? Like.exists({ post: doc._id, user: currentUserId }) : Promise.resolve(false),
    currentUserId ? Bookmark.exists({ post: doc._id, user: currentUserId }) : Promise.resolve(false),
  ]);
  return {
    ...doc,
    id: doc._id.toString(),
    isLiked: Boolean(isLiked),
    isBookmarked: Boolean(isBookmarked),
    isMine: currentUserId ? doc.author?._id?.toString() === currentUserId || doc.author?.toString() === currentUserId : false,
    media: (doc.media ?? []).map((m) => ({ url: m.url, type: m.type, publicId: m.publicId ?? "" })),
  };
}

/**
 * Shape many posts in one batch (single Like/Bookmark query each) — avoids
 * the N+1 query storm of calling [shapePost] in a loop.
 */
export async function shapePosts(posts, currentUserId) {
  if (posts.length === 0) return [];
  const ids = posts.map((p) => (p._doc ?? p)._id);
  const userId = currentUserId?.toString();
  let liked = new Set();
  let bookmarked = new Set();
  if (userId) {
    const [likes, bookmarks] = await Promise.all([
      Like.find({ post: { $in: ids }, user: userId }).select("post").lean(),
      Bookmark.find({ post: { $in: ids }, user: userId }).select("post").lean(),
    ]);
    liked = new Set(likes.map((l) => l.post.toString()));
    bookmarked = new Set(bookmarks.map((b) => b.post.toString()));
  }
  return posts.map((post) => {
    const doc = post._doc ?? post;
    const id = doc._id.toString();
    return {
      ...doc,
      id,
      isLiked: liked.has(id),
      isBookmarked: bookmarked.has(id),
      isMine: userId ? doc.author?._id?.toString() === userId || doc.author?.toString() === userId : false,
      media: (doc.media ?? []).map((m) => ({ url: m.url, type: m.type, publicId: m.publicId ?? "" })),
    };
  });
}

/** Shape a post list into the Reel shape used by the Reels tab + profile. */
export function toReelShape(post) {
  const p = post._doc ?? post;
  return {
    id: p.id ?? p._id.toString(),
    user: p.author,
    videoUrl: (p.media ?? []).find((m) => m.type === "video")?.url ?? "",
    caption: p.caption ?? "",
    likes: p.likesCount ?? 0,
    comments: p.commentsCount ?? 0,
    shares: p.sharesCount ?? 0,
    plays: 0,
    isLiked: p.isLiked ?? false,
    isBookmarked: p.isBookmarked ?? false,
    trust: p.trust ?? null,
  };
}

/** Create a post; optionally upload media and run AI trust + fact-check analysis. */
export async function createPost(req, res, next) {
  try {
    const { caption = "", hashtags = [], mentions = [], location = "" } = req.body;

    const mediaList = [];
    const files = req.files ?? [];
    for (const file of files) {
      const uploaded = await media.upload({ buffer: file.buffer });
      mediaList.push({
        url: uploaded.url,
        type: file.mimetype.startsWith("video/") ? "video" : "image",
        publicId: uploaded.publicId,
      });
    }

    const post = await Post.create({
      author: req.user._id,
      caption,
      media: mediaList,
      hashtags: Array.isArray(hashtags) ? hashtags : [],
      mentions: await resolveMentions(mentions),
      location,
    });

    // Kick off trust analysis + fact-check in the background.
    ai.analyzeText({ text: caption })
      .then(async (result) => {
        const factChecks = (result.factChecks ?? []).map((fc) => ({
          publisher: fc.publisher ?? "",
          title: fc.title ?? "",
          url: fc.url ?? "",
          rating: fc.rating ?? "",
          checkedDate: fc.checkedDate ?? null,
        }));
        const trust = await TrustResult.create({
          post: post._id,
          userId: req.user._id,
          score: result.score ?? 50,
          label: result.label ?? "Watch",
          factors: result.factors ?? [],
          factChecks,
        });
        await Post.findByIdAndUpdate(post._id, {
          trustCheck: {
            status: result.label === "Restricted" ? "restricted" : result.label === "Watch" ? "flagged" : "verified",
            score: result.score ?? 50,
            evidence: factChecks[0]?.title ?? "",
          },
        });
        await Notification.create({
          user: req.user._id,
          type: "trust",
          text: `Your post's trust analysis scored ${Math.round(result.score ?? 50)} — ${result.label}.`,
          isTrustEvent: true,
          post: post._id,
        });
        // Aggregate the user's live trust score from all real AI results.
        await recomputeUserTrust(req.user._id);
        await cache.delPattern(`feed:*`);
        return trust;
      })
      .catch((err) => console.warn("[posts] trust analysis failed:", err.message));

    res.status(201).json({ post: await shapePost(post, req.user._id.toString()) });
  } catch (err) {
    next(err);
  }
}

export async function getPost(req, res, next) {
  try {
    const post = await Post.findById(req.params.id)
      .populate("author", "name avatar username trustLabel trustScore isVerified")
      .lean();
    if (!post) return res.status(404).json({ error: "Post not found" });
    const trust = await TrustResult.findOne({ post: post._id }).lean();
    const shaped = await shapePost({ ...post, _doc: post }, req.user._id.toString());
    res.json({ post: { ...shaped, trust } });
  } catch (err) {
    next(err);
  }
}

/** List posts by a given author (or the current user when `me`). */
export async function listPostsByUser(req, res, next) {
  try {
    const authorId = req.params.userId === "me" ? req.user._id : req.params.userId;
    const posts = await Post.find({ author: authorId, moderationStatus: "visible" })
      .sort({ createdAt: -1 })
      .limit(50)
      .populate("author", "name avatar username trustLabel trustScore isVerified")
      .lean();
    const userId = req.user._id.toString();
    const trustResults = await TrustResult.find({
      post: { $in: posts.map((p) => p._id) },
    }).lean();
    const trustByPost = new Map(trustResults.map((t) => [t.post.toString(), t]));
    const shaped = await shapePosts(
      posts.map((p) => ({ ...p, _doc: p })),
      userId,
    );
    res.json({ data: shaped.map((p) => ({ ...p, trust: trustByPost.get(p.id) ?? null })) });
  } catch (err) {
    next(err);
  }
}

/** Delete a post (own post or moderator). */
export async function deletePost(req, res, next) {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: "Post not found" });
    const isOwner = post.author.toString() === req.user._id.toString();
    const isMod = ["moderator", "admin"].includes(req.user.role);
    if (!isOwner && !isMod) {
      return res.status(403).json({ error: "Not allowed to delete this post" });
    }
    for (const m of post.media) {
      if (m.publicId) await media.delete(m.publicId);
    }
    await Promise.all([
      Post.findByIdAndDelete(post._id),
      TrustResult.deleteMany({ post: post._id }),
      Comment.deleteMany({ post: post._id }),
      Like.deleteMany({ post: post._id }),
      Bookmark.deleteMany({ post: post._id }),
    ]);
    await cache.delPattern(`feed:*`);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

/* ── Likes ───────────────────────────────────────────────────────────── */

export async function toggleLike(req, res, next) {
  try {
    const { id } = req.params;
    const post = await Post.findById(id);
    if (!post) return res.status(404).json({ error: "Post not found" });

    const existing = await Like.findOne({ post: id, user: req.user._id });
    if (existing) {
      await Like.deleteOne({ _id: existing._id });
      await Post.findByIdAndUpdate(id, { $inc: { likesCount: -1 } });
      return res.json({ liked: false, likesCount: Math.max(0, post.likesCount - 1) });
    }

    await Like.create({ post: id, user: req.user._id });
    await Post.findByIdAndUpdate(id, { $inc: { likesCount: 1 } });
    if (post.author.toString() !== req.user._id.toString()) {
      const notification = await Notification.create({
        user: post.author,
        actor: req.user._id,
        type: "like",
        text: "liked your post.",
        post: post._id,
      });
      emitToUser(post.author, "notify:new", {
        id: notification._id.toString(),
        type: "like",
        actor: req.user._id,
        text: "liked your post.",
        postPreview: post.media?.[0]?.url ?? null,
        isRead: false,
        createdAt: notification.createdAt,
      });
    }
    res.json({ liked: true, likesCount: post.likesCount + 1 });
  } catch (err) {
    next(err);
  }
}

/* ── Bookmarks ───────────────────────────────────────────────────────── */

export async function toggleBookmark(req, res, next) {
  try {
    const { id } = req.params;
    const post = await Post.findById(id);
    if (!post) return res.status(404).json({ error: "Post not found" });

    const existing = await Bookmark.findOne({ post: id, user: req.user._id });
    if (existing) {
      await Bookmark.deleteOne({ _id: existing._id });
      return res.json({ bookmarked: false });
    }
    await Bookmark.create({ post: id, user: req.user._id });
    res.json({ bookmarked: true });
  } catch (err) {
    next(err);
  }
}

export async function getSavedPosts(req, res, next) {
  try {
    const bookmarks = await Bookmark.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .populate({
        path: "post",
        populate: { path: "author", select: "name avatar username trustLabel trustScore isVerified" },
      })
      .lean();
    const userId = req.user._id.toString();
    const posts = bookmarks.map((b) => b.post).filter(Boolean);
    const trustResults = await TrustResult.find({
      post: { $in: posts.map((p) => p._id) },
    }).lean();
    const trustByPost = new Map(trustResults.map((t) => [t.post.toString(), t]));
    const shaped = await shapePosts(
      posts.map((p) => ({ ...p, _doc: p })),
      userId,
    );
    res.json({ data: shaped.map((p) => ({ ...p, trust: trustByPost.get(p.id) ?? null })) });
  } catch (err) {
    next(err);
  }
}

/* ── Comments ────────────────────────────────────────────────────────── */

export async function getComments(req, res, next) {
  try {
    const comments = await Comment.find({ post: req.params.id })
      .sort({ createdAt: -1 })
      .limit(100)
      .populate("author", "name avatar username trustLabel trustScore isVerified")
      .lean();
    res.json({
      data: comments.map((c) => ({
        id: c._id.toString(),
        author: c.author,
        text: c.text,
        likes: c.likes ?? 0,
        createdAt: c.createdAt,
      })),
    });
  } catch (err) {
    next(err);
  }
}

export async function addComment(req, res, next) {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ error: "comment text required" });
    }
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: "Post not found" });

    const comment = await Comment.create({
      post: post._id,
      author: req.user._id,
      text: text.trim().slice(0, 1000),
    });
    await Post.findByIdAndUpdate(post._id, { $inc: { commentsCount: 1 } });
    if (post.author.toString() !== req.user._id.toString()) {
      const notification = await Notification.create({
        user: post.author,
        actor: req.user._id,
        type: "comment",
        text: `commented: "${text.trim().slice(0, 60)}${text.trim().length > 60 ? "…" : ""}"`,
        post: post._id,
      });
      emitToUser(post.author, "notify:new", {
        id: notification._id.toString(),
        type: "comment",
        actor: req.user._id,
        text: `commented: "${text.trim().slice(0, 60)}${text.trim().length > 60 ? "…" : ""}"`,
        postPreview: post.media?.[0]?.url ?? null,
        isRead: false,
        createdAt: notification.createdAt,
      });
    }

    const full = await Comment.findById(comment._id).populate(
      "author",
      "name avatar username trustLabel trustScore isVerified",
    );
    res.status(201).json({
      comment: {
        id: full._id.toString(),
        author: full.author,
        text: full.text,
        likes: full.likes ?? 0,
        createdAt: full.createdAt,
      },
    });
  } catch (err) {
    next(err);
  }
}
