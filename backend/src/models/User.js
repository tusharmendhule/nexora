import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true },
    passwordHash: { type: String, default: "" },
    name: { type: String, required: true, trim: true },
    username: { type: String, unique: true, sparse: true, trim: true },
    avatar: { type: String, default: "" },
    coverUrl: { type: String, default: "" },
    bio: { type: String, default: "", maxlength: 160 },
    location: { type: String, default: "" },
    link: { type: String, default: "" },
    role: {
      type: String,
      enum: ["user", "moderator", "admin"],
      default: "user",
    },
    trustScore: { type: Number, min: 0, max: 100, default: 50 },
    trustLabel: {
      type: String,
      enum: ["Verified", "Vetted", "Premium", "Watch", "Restricted"],
      default: "Watch",
    },
    isVerified: { type: Boolean, default: false },
    isBanned: { type: Boolean, default: false },
    followersCount: { type: Number, default: 0 },
    followingCount: { type: Number, default: 0 },
  },
  { timestamps: true },
);

userSchema.index({ trustScore: -1 });

export const User = mongoose.model("User", userSchema);
