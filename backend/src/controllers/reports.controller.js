import { Report } from "../models/Report.js";

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
