import mongoose from "mongoose";

const reportSchema = new mongoose.Schema(
  {
    reporter: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    targetType: {
      type: String,
      enum: ["post", "user", "comment"],
      required: true,
    },
    targetId: { type: mongoose.Schema.Types.ObjectId, required: true },
    reason: { type: String, required: true },
    details: { type: String, default: "" },
    status: {
      type: String,
      enum: ["open", "reviewing", "resolved", "dismissed"],
      default: "open",
    },
    resolution: { type: String, default: "" },
  },
  { timestamps: true },
);

reportSchema.index({ status: 1, createdAt: -1 });

export const Report = mongoose.model("Report", reportSchema);
