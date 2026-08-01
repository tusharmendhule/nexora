import { User } from "../models/User.js";
import { Post } from "../models/Post.js";
import { Report } from "../models/Report.js";
import { Follow } from "../models/Follow.js";
import { TrustResult } from "../models/TrustResult.js";
import { Notification } from "../models/Notification.js";

/** Platform-wide stats for the admin dashboard. */
export async function getAdminStats(req, res, next) {
  try {
    const [users, posts, openReports, follows, trustResults, notifications] =
      await Promise.all([
        User.countDocuments(),
        Post.countDocuments(),
        Report.countDocuments({ status: { $in: ["open", "reviewing"] } }),
        Follow.countDocuments(),
        TrustResult.countDocuments(),
        Notification.countDocuments(),
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
