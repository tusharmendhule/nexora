import { Report } from "../models/Report.js";
import { Post } from "../models/Post.js";
import { ModerationLog } from "../models/ModerationLog.js";

/** List open/queued reports for the moderation queue (with post + author info). */
export async function getQueue(req, res, next) {
  try {
    const status = req.query.status ?? "open";
    const reports = await Report.find({ status })
      .sort({ createdAt: 1 })
      .limit(50)
      .populate("reporter", "name avatar username trustLabel trustScore")
      .lean();

    const data = [];
    for (const report of reports) {
      let target = null;
      if (report.targetType === "post") {
        target = await Post.findById(report.targetId).populate(
          "author",
          "name avatar username trustLabel trustScore",
        );
      } else if (report.targetType === "user") {
        target = { _id: report.targetId };
      }
      data.push({
        id: report._id.toString(),
        reportId: report._id.toString(),
        reportedUser: target?.author ?? null,
        reporter: report.reporter,
        reason: report.reason,
        details: report.details ?? "",
        preview: target?.media?.[0]?.url ?? "",
        caption: target?.caption ?? "",
        severity: report.reason === "harassment" || report.reason === "violence" ? 3 : report.reason === "spam" ? 2 : 1,
        reportedAt: report.createdAt,
        status: report.status,
      });
    }
    res.json({ data });
  } catch (err) {
    next(err);
  }
}

/** Take a moderation action on a post and log it. */
export async function takeAction(req, res, next) {
  try {
    const { action, targetType, targetId, reason } = req.body;
    if (!action || !targetType || !targetId) {
      return res.status(400).json({ error: "action, targetType and targetId required" });
    }

    if (targetType === "post" && action === "remove") {
      await Post.findByIdAndUpdate(targetId, { moderationStatus: "removed" });
    } else if (targetType === "post" && action === "approve") {
      await Post.findByIdAndUpdate(targetId, { moderationStatus: "visible" });
    }

    await ModerationLog.create({
      moderator: req.user._id,
      action,
      targetType,
      targetId,
      reason,
    });

    if (req.body.reportId) {
      await Report.findByIdAndUpdate(req.body.reportId, {
        status: "resolved",
        resolution: reason,
      });
    }

    res.json({ ok: true, action, targetId });
  } catch (err) {
    next(err);
  }
}
