import axios from "axios";
import { env } from "../config/env.js";

const FACTCHECK_URL = "https://factchecktools.googleapis.com/v1alpha1/claims:search";

/**
 * LEGACY / UNUSED — superseded by the AI service.
 *
 * Fact-checking now runs in the AI service (ai-service/) via Gemini
 * (set GEMINI_API_KEY in ai-service/.env). This module queried the Google
 * Fact Check Tools API but is not imported anywhere and the backend env
 * never defined factCheckApiKey, so it always returned []. Kept only as a
 * reference; do not wire it up.
 */
export async function searchFactChecks({ query, languageCode = "en" }) {
  if (!env.factCheckApiKey) return [];
  try {
    const { data } = await axios.get(FACTCHECK_URL, {
      params: { query, languageCode, key: env.factCheckApiKey },
      timeout: 10_000,
    });
    return (data.claims ?? []).map((claim) => ({
      publisher: claim.claimReview?.[0]?.publisher?.name ?? "Unknown",
      title: claim.claimReview?.[0]?.title ?? "",
      url: claim.claimReview?.[0]?.url ?? "",
      rating: claim.claimReview?.[0]?.textualRating ?? "",
      checkedDate: claim.claimReview?.[0]?.reviewDate ?? null,
    }));
  } catch (err) {
    console.warn("[factcheck] lookup failed:", err.message);
    return [];
  }
}
