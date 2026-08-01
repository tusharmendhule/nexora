import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    actor: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    type: {
      type: String,
      enum: ["like", "comment", "follow", "mention", "trust", "system"],
      required: true,
    },
    text: { type: String, default: "" },
    post: { type: mongoose.Schema.Types.ObjectId, ref: "Post" },
    isRead: { type: Boolean, default: false },
    isTrustEvent: { type: Boolean, default: false },
  },
  { timestamps: true },
);

notificationSchema.index({ user: 1, createdAt: -1 });
notificationSchema.index({ user: 1, isRead: 1 });

export const Notification = mongoose.model("Notification", notificationSchema);
