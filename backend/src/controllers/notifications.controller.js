import { Notification } from "../models/Notification.js";

/** List the current user's notifications, newest first. */
export async function listNotifications(req, res, next) {
  try {
    const items = await Notification.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50)
      .populate("actor", "name avatar username trustLabel trustScore isVerified")
      .populate({
        path: "post",
        select: "media caption",
      })
      .lean();

    res.json({
      data: items.map((n) => ({
        id: n._id.toString(),
        type: n.type,
        user: n.actor ?? { name: "Nexora", username: "nexora" },
        text: n.text ?? "",
        postPreview:
          n.post?.media?.[0]?.url ?? null,
        isRead: n.isRead,
        isTrustEvent: n.isTrustEvent,
        createdAt: n.createdAt,
      })),
    });
  } catch (err) {
    next(err);
  }
}

/** Mark a single notification as read. */
export async function markRead(req, res, next) {
  try {
    await Notification.findByIdAndUpdate(req.params.id, { isRead: true });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

/** Mark every notification as read. */
export async function markAllRead(req, res, next) {
  try {
    await Notification.updateMany({ user: req.user._id, isRead: false }, { isRead: true });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}
