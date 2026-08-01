import mongoose from "mongoose";

const trustResultSchema = new mongoose.Schema(
  {
    post: { type: mongoose.Schema.Types.ObjectId, ref: "Post", required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    score: { type: Number, min: 0, max: 100, required: true },
    label: {
      type: String,
      enum: ["Verified", "Vetted", "Premium", "Watch", "Restricted"],
      required: true,
    },
    factors: [
      {
        name: String,
        value: Number,
        detail: String,
      },
    ],
    checks: [
      {
        name: String,
        label: String,
        score: Number,
        level: {
          type: String,
          enum: ["none", "low", "medium", "high"],
          default: "none",
        },
        flags: [String],
        detail: String,
      },
    ],
    factChecks: [
      {
        publisher: String,
        title: String,
        url: String,
        rating: String,
        checkedDate: Date,
      },
    ],
  },
  { timestamps: true },
);

trustResultSchema.index({ post: 1 });
trustResultSchema.index({ userId: 1, createdAt: -1 });

export const TrustResult = mongoose.model("TrustResult", trustResultSchema);
