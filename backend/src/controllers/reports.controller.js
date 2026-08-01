import { Report } from "../models/Report.js";
import { Post } from "../models/Post.js";

/** File a new report against a post, user or comment. */
export async function createReport(req, res, next) {
  try {
    const { targetType, targetId, reason, details } = req.body;
    if (!targetType || !targetId || !reason) {
      return res
        .status(400)
        .json({ error: "targetType, targetId and reason required" });
    }
    const report = await Report.create({
      reporter: req.user._id,
      targetType,
      targetId,
      reason,
      details,
    });
    res.status(201).json({ report });
  } catch (err) {
    next(err);
  }
}

/** List reports with filters + pagination (moderators/admins). */
export async function listReports(req, res, next) {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Number(req.query.limit) || 20);
    const status = req.query.status;
    const filter = {};
    if (status) filter.status = status;

    const [total, reports] = await Promise.all([
      Report.countDocuments(filter),
      Report.find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .populate("reporter", "name username avatar"),
    ]);

    res.json({
      data: reports,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
}

/** Report detail with the targeted post + author for the moderation console. */
export async function getReport(req, res, next) {
  try {
    const report = await Report.findById(req.params.id)
      .populate("reporter", "name username avatar trustLabel trustScore")
      .lean();
    if (!report) return res.status(404).json({ error: "Report not found" });

    let target = null;
    if (report.targetType === "post") {
      target = await Post.findById(report.targetId)
        .populate("author", "name username avatar trustLabel trustScore")
        .lean();
    }

    res.json({ report: { ...report, target } });
  } catch (err) {
    next(err);
  }
}
