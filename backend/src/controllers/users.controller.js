import { User } from "../models/User.js";
import { Follow } from "../models/Follow.js";
import { Post } from "../models/Post.js";
import { TrustResult } from "../models/TrustResult.js";
import { Bookmark } from "../models/Bookmark.js";
import { Notification } from "../models/Notification.js";
import { toUserResponse } from "./auth.controller.js";
import { emitToUser } from "../services/socket.service.js";

/** Search users, posts and hashtags with a single query. */
export async function searchAll(req, res, next) {
  try {
    const q = (req.query.q ?? "").trim();
    if (!q) {
      return res.status(400).json({ error: "q query parameter required" });
    }

    const regex = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
    const users = await User.find({ $or: [{ name: regex }, { username: regex }] })
      .limit(10)
      .select("name avatar username trustLabel trustScore bio")
      .lean();
    const posts = await Post.find({
      moderationStatus: "visible",
      $or: [{ caption: regex }, { hashtags: regex }],
    })
      .sort({ createdAt: -1 })
      .limit(20)
      .populate("author", "name avatar username trustLabel trustScore isVerified")
      .lean();

    const userId = req.user._id.toString();
    const trustResults = await TrustResult.find({
      post: { $in: posts.map((p) => p._id) },
    }).lean();
    const trustByPost = new Map(trustResults.map((t) => [t.post.toString(), t]));
    const { shapePosts } = await import("./posts.controller.js");
    const shaped = await shapePosts(
      posts.map((p) => ({ ...p, _doc: p })),
      userId,
    );

    res.json({
      data: {
        people: users.map((u) => toUserResponse(u)),
        posts: shaped.map((p) => ({ ...p, trust: trustByPost.get(p.id) ?? null })),
        tags: posts
          .flatMap((p) => p.hashtags ?? [])
          .filter((t) => t.toLowerCase().includes(q.toLowerCase()))
          .slice(0, 10),
      },
    });
  } catch (err) {
    next(err);
  }
}

/** Explore: trending posts + trending hashtags. */
export async function explore(req, res, next) {
  try {
    const posts = await Post.find({ moderationStatus: "visible" })
      .sort({ likesCount: -1, createdAt: -1 })
      .limit(30)
      .populate("author", "name avatar username trustLabel trustScore isVerified")
      .lean();

    const hashtagCounts = new Map();
    for (const p of posts) {
      for (const h of p.hashtags ?? []) {
        hashtagCounts.set(h, (hashtagCounts.get(h) ?? 0) + 1);
      }
    }
    const topics = [...hashtagCounts.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([tag]) => `#${tag}`);

    const userId = req.user._id.toString();
    const trustResults = await TrustResult.find({
      post: { $in: posts.map((p) => p._id) },
    }).lean();
    const trustByPost = new Map(trustResults.map((t) => [t.post.toString(), t]));
    const { shapePosts } = await import("./posts.controller.js");
    const shaped = await shapePosts(
      posts.map((p) => ({ ...p, _doc: p })),
      userId,
    );

    res.json({
      data: {
        items: shaped.map((p) => ({ ...p, trust: trustByPost.get(p.id) ?? null })),
        topics,
      },
    });
  } catch (err) {
    next(err);
  }
}

/** Reels: posts that carry video media. */
export async function getReels(req, res, next) {
  try {
    const posts = await Post.find({
      moderationStatus: "visible",
      media: { $elemMatch: { type: "video" } },
    })
      .sort({ createdAt: -1 })
      .limit(50)
      .populate("author", "name avatar username trustLabel trustScore isVerified")
      .lean();

    const userId = req.user._id.toString();
    const trustResults = await TrustResult.find({
      post: { $in: posts.map((p) => p._id) },
    }).lean();
    const trustByPost = new Map(trustResults.map((t) => [t.post.toString(), t]));
    const { shapePosts, toReelShape } = await import("./posts.controller.js");
    const shaped = await shapePosts(
      posts.map((p) => ({ ...p, _doc: p })),
      userId,
    );

    res.json({
      data: shaped.map((p) => toReelShape({ ...p, trust: trustByPost.get(p.id) ?? null })),
    });
  } catch (err) {
    next(err);
  }
}

/** Resolve a `:id` param that may be an ObjectId or a username. */
async function resolveUser(param) {
  const isObjectId =
    typeof param === "string" && /^[0-9a-fA-F]{24}$/.test(param);
  if (isObjectId) {
    return User.findById(param);
  }
  return User.findOne({ username: param });
}

/** Public profile payload for a user id (or username). */
export async function getUserProfile(req, res, next) {
  try {
    const user = await resolveUser(req.params.id);
    if (!user) return res.status(404).json({ error: "User not found" });

    const [isFollowing, posts, saved] = await Promise.all([
      Follow.exists({ follower: req.user._id, following: user._id }),
      Post.find({ author: user._id, moderationStatus: "visible" })
        .sort({ createdAt: -1 })
        .limit(40)
        .populate("author", "name avatar username trustLabel trustScore isVerified")
        .lean(),
      Bookmark.find({ user: req.user._id })
        .sort({ createdAt: -1 })
        .populate({
          path: "post",
          populate: { path: "author", select: "name avatar username trustLabel trustScore isVerified" },
        })
        .lean(),
    ]);

    const userId = req.user._id.toString();
    const { shapePosts, toReelShape } = await import("./posts.controller.js");

    const reels = await Post.find({
      author: user._id,
      moderationStatus: "visible",
      media: { $elemMatch: { type: "video" } },
    })
      .sort({ createdAt: -1 })
      .limit(20)
      .populate("author", "name avatar username trustLabel trustScore isVerified")
      .lean();

    const trustResults = await TrustResult.find({
      post: { $in: [...posts, ...reels, ...saved.map((b) => b.post)].filter(Boolean).map((p) => p._id) },
    }).lean();
    const trustByPost = new Map(trustResults.map((t) => [t.post.toString(), t]));

    const shapedPosts = await shapePosts(
      posts.map((p) => ({ ...p, _doc: p })),
      userId,
    );
    const shapedSaved = await shapePosts(
      saved.map((b) => b.post).filter(Boolean).map((p) => ({ ...p, _doc: p })),
      userId,
    );
    const shapedReels = await shapePosts(
      reels.map((p) => ({ ...p, _doc: p })),
      userId,
    );

    const profile = toUserResponse(user);
    profile.isFollowing = Boolean(isFollowing);
    profile.posts = shapedPosts.length;
    profile.reels = shapedReels.length;
    profile.saved = shapedSaved.length;

    res.json({
      user: profile,
      posts: shapedPosts.map((p) => ({ ...p, trust: trustByPost.get(p.id) ?? null })),
      reels: shapedReels.map((r) => toReelShape({ ...r, trust: trustByPost.get(r.id) ?? null })),
      saved: shapedSaved.map((p) => ({ ...p, trust: trustByPost.get(p.id) ?? null })),
    });
  } catch (err) {
    next(err);
  }
}

/** Follow or unfollow a user. */
export async function toggleFollow(req, res, next) {
  try {
    const target = await resolveUser(req.params.id);
    if (!target) return res.status(404).json({ error: "User not found" });
    if (target._id.toString() === req.user._id.toString()) {
      return res.status(400).json({ error: "You cannot follow yourself" });
    }

    const existing = await Follow.findOne({
      follower: req.user._id,
      following: target._id,
    });

    if (existing) {
      await Follow.deleteOne({ _id: existing._id });
      await User.findByIdAndUpdate(target._id, { $inc: { followersCount: -1 } });
      await User.findByIdAndUpdate(req.user._id, { $inc: { followingCount: -1 } });
      return res.json({ following: false, followers: Math.max(0, target.followersCount - 1) });
    }

    await Follow.create({ follower: req.user._id, following: target._id });
    await User.findByIdAndUpdate(target._id, { $inc: { followersCount: 1 } });
    await User.findByIdAndUpdate(req.user._id, { $inc: { followingCount: 1 } });
    const notification = await Notification.create({
      user: target._id,
      actor: req.user._id,
      type: "follow",
      text: "started following you.",
    });
    emitToUser(target._id, "notify:new", {
      id: notification._id.toString(),
      type: "follow",
      actor: req.user._id,
      text: "started following you.",
      postPreview: null,
      isRead: false,
      createdAt: notification.createdAt,
    });
    res.json({ following: true, followers: target.followersCount + 1 });
  } catch (err) {
    next(err);
  }
}

/** Suggested members to follow (highest trust first). */
export async function suggestUsers(req, res, next) {
  try {
    const following = await Follow.find({ follower: req.user._id }).select("following");
    const excluded = following.map((f) => f.following);
    excluded.push(req.user._id);
    const users = await User.find({ _id: { $nin: excluded } })
      .sort({ trustScore: -1, followersCount: -1 })
      .limit(8)
      .lean();
    res.json({ data: users.map((u) => toUserResponse(u)) });
  } catch (err) {
    next(err);
  }
}
