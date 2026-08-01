import mongoose from "mongoose";

/**
 * Refresh tokens enable long-lived sessions without re-authentication while
 * staying revocable. Each login issues a fresh pair; the refresh token is
 * stored (hashed) so it can be rotated and invalidated on logout.
 */
const refreshTokenSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    tokenHash: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    revokedAt: { type: Date, default: null },
    replacedBy: { type: String, default: null },
    userAgent: { type: String, default: "" },
    ip: { type: String, default: "" },
  },
  { timestamps: true },
);

refreshTokenSchema.index({ user: 1, expiresAt: 1 });
refreshTokenSchema.index({ tokenHash: 1 }, { unique: true });

export const RefreshToken = mongoose.model("RefreshToken", refreshTokenSchema);
