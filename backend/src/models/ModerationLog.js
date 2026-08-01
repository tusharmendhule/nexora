import mongoose from "mongoose";

const moderationLogSchema = new mongoose.Schema(
  {
    moderator: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    action: {
      type: String,
      enum: ["approve", "flag", "remove", "restrict", "dismiss"],
      required: true,
    },
    targetType: {
      type: String,
      enum: ["post", "user", "comment"],
      required: true,
    },
    targetId: { type: mongoose.Schema.Types.ObjectId, required: true },
    reason: { type: String, default: "" },
  },
  { timestamps: true },
);

moderationLogSchema.index({ moderator: 1, createdAt: -1 });

export const ModerationLog = mongoose.model(
  "ModerationLog",
  moderationLogSchema,
);
