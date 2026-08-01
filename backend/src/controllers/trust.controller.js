import { User } from "../models/User.js";
import { TrustResult } from "../models/TrustResult.js";
import { ai } from "../services/ai.service.js";

/** Recompute a user's trust score from their post trust results. */
export async function recomputeTrust(req, res, next) {
  try {
    const results = await TrustResult.find({ userId: req.user._id }).lean();
    const avg =
      results.length === 0
        ? 50
        : results.reduce((sum, r) => sum + r.score, 0) / results.length;

    const label =
      avg >= 75 ? "Verified" : avg >= 60 ? "Vetted" : avg >= 45 ? "Watch" : "Restricted";
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { trustScore: Math.round(avg), trustLabel: label },
      { new: true },
    );
    res.json({ user, historyCount: results.length });
  } catch (err) {
    next(err);
  }
}

/** Fact-check a claim via the AI service (Gemini-backed). */
export async function verifyClaim(req, res, next) {
  try {
    const { query } = req.query;
    if (!query) return res.status(400).json({ error: "query parameter required" });
    const result = await ai.factCheck({ query });
    res.json(result);
  } catch (err) {
    next(err);
  }
}

/** Trust history (by week) + live factors for the Trust Center. */
export async function getTrustOverview(req, res, next) {
  try {
    const user = await User.findById(req.user._id);
    const results = await TrustResult.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .limit(8)
      .lean();

    const history = results
      .slice()
      .reverse()
      .map((r, i) => ({
        week: `W${i + 1}`,
        score: Math.round(r.score ?? 50),
        label: r.label ?? "Watch",
      }));

    const latest = results[0];
    const factors = latest?.factors ?? [];
    const verifiedCount = results.filter((r) => (r.score ?? 0) >= 75).length;

    res.json({
      user: {
        id: user._id.toString(),
        trustScore: user.trustScore ?? 50,
        trustLabel: user.trustLabel ?? "Watch",
      },
      history,
      factors: factors.map((f, i) => ({
        label: f.name ?? `Factor ${i + 1}`,
        value: Math.round(((f.value ?? 0.5) + 0.5) * 50),
      })),
      stats: {
        postsAnalyzed: results.length,
        verifiedCount,
        avgScore: results.length
          ? Math.round(results.reduce((s, r) => s + (r.score ?? 0), 0) / results.length)
          : 50,
      },
    });
  } catch (err) {
    next(err);
  }
}
