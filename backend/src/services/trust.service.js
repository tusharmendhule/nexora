import { User } from "../models/User.js";
import { Notification } from "../models/Notification.js";
import { TrustResult } from "../models/TrustResult.js";
import { emitToUser } from "./socket.service.js";

/** Map a score to the colour-coded trust label (mirrors the AI service). */
export function labelForScore(score) {
  if (score >= 75) return "Verified";
  if (score >= 60) return "Vetted";
  if (score >= 45) return "Watch";
  return "Restricted";
}

/**
 * Recompute a user's aggregate trust score from their real post-analysis
 * results (AI score + fact-check evidence). Creates a real-time notification
 * when the label changes so the client UI stays in sync.
 */
export async function recomputeUserTrust(userId) {
  const results = await TrustResult.find({ userId }).lean();
  const avg =
    results.length === 0
      ? 50
      : results.reduce((sum, r) => sum + (r.score ?? 50), 0) / results.length;

  const label = labelForScore(avg);
  const user = await User.findById(userId);
  if (!user) return null;

  const previous = user.trustLabel;
  const updated = await User.findByIdAndUpdate(
    userId,
    { trustScore: Math.round(avg), trustLabel: label },
    { new: true },
  );

  if (previous && previous !== label) {
    try {
      const notification = await Notification.create({
        user: userId,
        type: "trust",
        text: `Your Trust Label is now ${label} (score ${Math.round(avg)}).`,
        isTrustEvent: true,
      });
      emitToUser(userId, "notify:new", {
        id: notification._id.toString(),
        type: "trust",
        actor: userId,
        text: `Your Trust Label is now ${label} (score ${Math.round(avg)}).`,
        postPreview: null,
        isRead: false,
        createdAt: notification.createdAt,
      });
    } catch (err) {
      console.warn("[trust] notification failed:", err.message);
    }
  }

  return { user: updated, historyCount: results.length, labelChanged: previous !== label };
}
