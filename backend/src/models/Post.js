import mongoose from "mongoose";

const postSchema = new mongoose.Schema(
  {
    author: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    caption: { type: String, default: "", maxlength: 2200 },
    media: [
      {
        url: { type: String, required: true },
        type: { type: String, enum: ["image", "video"], required: true },
        publicId: { type: String, default: "" },
      },
    ],
    hashtags: [{ type: String }],
    mentions: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    likesCount: { type: Number, default: 0 },
    commentsCount: { type: Number, default: 0 },
    sharesCount: { type: Number, default: 0 },
    trustCheck: {
      status: {
        type: String,
        enum: ["pending", "verified", "flagged", "restricted"],
        default: "pending",
      },
      score: { type: Number, default: null },
      evidence: { type: String, default: "" },
    },
    moderationStatus: {
      type: String,
      enum: ["visible", "under_review", "removed"],
      default: "visible",
    },
  },
  { timestamps: true },
);

postSchema.index({ author: 1, createdAt: -1 });
postSchema.index({ moderationStatus: 1, createdAt: -1 });
postSchema.index({ hashtags: 1 });
postSchema.index({ "media.type": 1, createdAt: -1 });

export const Post = mongoose.model("Post", postSchema);
