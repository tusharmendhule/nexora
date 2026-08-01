import axios from "axios";
import { env } from "../config/env.js";

const FACTCHECK_URL = "https://factchecktools.googleapis.com/v1alpha1/claims:search";

/**
 * Query the Google Fact Check Tools API for known claim reviews.
 * Returns [] when no API key is configured (or on failure).
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
