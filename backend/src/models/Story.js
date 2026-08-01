import mongoose from "mongoose";

const storySchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    imageUrl: { type: String, required: true },
    caption: { type: String, default: "" },
    expiresAt: { type: Date, required: true },
  },
  { timestamps: true },
);

storySchema.index({ expiresAt: 1 });

export const Story = mongoose.model("Story", storySchema);
