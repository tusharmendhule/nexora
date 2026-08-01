import mongoose from "mongoose";

/**
 * Platform-wide admin settings, stored as a single document so switches in
 * the admin dashboard actually change server behaviour:
 *  - maintenanceMode: read-only for members (mutations blocked)
 *  - verifiedOnlyExplore: explore feed shows verified creators only
 *  - aiTriage: auto-flag low-risk reports with AI content checks
 */
const adminSettingsSchema = new mongoose.Schema(
  {
    maintenanceMode: { type: Boolean, default: false },
    verifiedOnlyExplore: { type: Boolean, default: false },
    aiTriage: { type: Boolean, default: true },
  },
  { timestamps: true },
);

/** Return the singleton settings doc, creating it with defaults on first use. */
adminSettingsSchema.statics.getSingleton = async function () {
  const existing = await this.findOne();
  if (existing) return existing;
  return this.create({});
};

export const AdminSettings = mongoose.model("AdminSettings", adminSettingsSchema);
