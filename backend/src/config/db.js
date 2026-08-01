import mongoose from "mongoose";
import { env } from "./env.js";

export async function connectDB() {
  if (!env.mongodbUri) {
    console.warn("[db] MONGODB_URI is not set — skipping database connection.");
    return null;
  }
  mongoose.connection.on("error", (err) =>
    console.error("[db] connection error:", err.message),
  );
  await mongoose.connect(env.mongodbUri);
  console.log("[db] connected to MongoDB Atlas");
  return mongoose.connection;
}
