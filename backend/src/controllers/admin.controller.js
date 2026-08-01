import { User } from "../models/User.js";
import { Post } from "../models/Post.js";
import { Report } from "../models/Report.js";
import { Follow } from "../models/Follow.js";
import { TrustResult } from "../models/TrustResult.js";
import { Notification } from "../models/Notification.js";
import { Like } from "../models/Like.js";
import { Comment } from "../models/Comment.js";
import { AdminSettings } from "../models/AdminSettings.js";

/** Load the singleton settings doc (creates it with defaults if absent). */
export async function getSettings() {
  return AdminSettings.getSingleton();
}

/** GET /admin/settings — current platform settings (admin only). */
export async function getAdminSettings(req, res, next) {
  try {
    const settings = await getSettings();
    res.json({
      settings: {
        maintenanceMode: settings.maintenanceMode,
        verifiedOnlyExplore: settings.verifiedOnlyExplore,
        aiTriage: settings.aiTriage,
      },
    });
  } catch (err) {
    next(err);
  }
}

/** PUT /admin/settings — persist admin dashboard switches (admin only). */
export async function updateAdminSettings(req, res, next) {
  try {
    const { maintenanceMode, verifiedOnlyExplore, aiTriage } = req.body ?? {};
    const settings = await getSettings();
    if (typeof maintenanceMode === "boolean") {
      settings.maintenanceMode = maintenanceMode;
    }
    if (typeof verifiedOnlyExplore === "boolean") {
      settings.verifiedOnlyExplore = verifiedOnlyExplore;
    }
    if (typeof aiTriage === "boolean") {
      settings.aiTriage = aiTriage;
    }
    await settings.save();
    res.json({
      settings: {
        maintenanceMode: settings.maintenanceMode,
        verifiedOnlyExplore: settings.verifiedOnlyExplore,
        aiTriage: settings.aiTriage,
      },
    });
  } catch (err) {
    next(err);
  }
}

/** List users with filters + pagination for the admin dashboard. */
export async function listUsers(req, res, next) {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Number(req.query.limit) || 20);
    const role = req.query.role;
    const q = req.query.q?.trim();

    const filter = {};
    if (role) filter.role = role;
    if (q) {
      filter.$or = [
        { name: { $regex: q, $options: "i" } },
        { username: { $regex: q, $options: "i" } },
        { email: { $regex: q, $options: "i" } },
      ];
    }

    const [total, users] = await Promise.all([
      User.countDocuments(filter),
      User.find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .select("name username email avatar role trustScore trustLabel isVerified createdAt"),
    ]);

    res.json({
      data: users,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
}

/** Change a user's role (admin only). Prevents self-demotion. */
export async function updateUserRole(req, res, next) {
  try {
    const { role } = req.body;
    if (!["user", "moderator", "admin"].includes(role)) {
      return res.status(400).json({ error: "Invalid role" });
    }
    const target = await User.findById(req.params.id);
    if (!target) return res.status(404).json({ error: "User not found" });
    if (target._id.toString() === req.user._id.toString() && role !== "admin") {
      return res.status(400).json({ error: "Cannot demote yourself" });
    }
    target.role = role;
    await target.save();
    res.json({ ok: true, user: target });
  } catch (err) {
    next(err);
  }
}

/** Ban / restore a user account (admin only). */
export async function toggleUserBan(req, res, next) {
  try {
    const target = await User.findById(req.params.id);
    if (!target) return res.status(404).json({ error: "User not found" });
    if (target._id.toString() === req.user._id.toString()) {
      return res.status(400).json({ error: "Cannot ban yourself" });
    }
    target.isBanned = !target.isBanned;
    await target.save();
    res.json({ ok: true, isBanned: target.isBanned });
  } catch (err) {
    next(err);
  }
}

/** Platform-wide stats for the admin dashboard. */
export async function getAdminStats(req, res, next) {
  try {
    const [users, posts, openReports, follows, trustResults, notifications, likes, comments] =
      await Promise.all([
        User.countDocuments(),
        Post.countDocuments(),
        Report.countDocuments({ status: { $in: ["open", "reviewing"] } }),
        Follow.countDocuments(),
        TrustResult.countDocuments(),
        Notification.countDocuments(),
        Like.countDocuments(),
        Comment.countDocuments(),
      ]);

    // 8-week growth (approximate from createdAt buckets).
    const now = Date.now();
    const growth = [];
    for (let i = 7; i >= 0; i--) {
      const from = new Date(now - (i + 1) * 7 * 24 * 3600 * 1000);
      const to = new Date(now - i * 7 * 24 * 3600 * 1000);
      const count = await User.countDocuments({ createdAt: { $gte: from, $lt: to } });
      growth.push({
        week: `W${8 - i}`,
        members: count,
      });
    }

    // Cumulative member count for each week.
    let cumulative = 0;
    const cumulativeGrowth = growth.map((g) => {
      cumulative += g.members;
      return { week: g.week, members: cumulative };
    });

    const topUsers = await User.find().sort({ trustScore: -1 }).limit(10).select(
      "name username avatar trustScore trustLabel role",
    );

    res.json({
      stats: {
        users,
        posts,
        openReports,
        follows,
        trustResults,
        notifications,
        likes,
        comments,
      },
      growth: cumulativeGrowth,
      topUsers: topUsers.map((u) => ({
        name: u.name,
        username: u.username,
        avatar: u.avatar,
        trustScore: u.trustScore,
        trustLabel: u.trustLabel,
        role: u.role,
      })),
    });
  } catch (err) {
    next(err);
  }
}

/** Moderation stats: pending, resolved today, avg response, trust actions. */
export async function getModerationStats(req, res, next) {
  try {
    const [pending, resolvedToday, logs] = await Promise.all([
      Report.countDocuments({ status: { $in: ["open", "reviewing"] } }),
      Report.countDocuments({
        status: "resolved",
        updatedAt: { $gte: new Date(Date.now() - 24 * 3600 * 1000) },
      }),
      (await import("../models/ModerationLog.js")).ModerationLog.countDocuments({
        createdAt: { $gte: new Date(Date.now() - 7 * 24 * 3600 * 1000) },
      }),
    ]);

    res.json({
      stats: {
        pending,
        resolvedToday,
        avgResponseHours: 0,
        trustActions: logs,
      },
    });
  } catch (err) {
    next(err);
  }
}
