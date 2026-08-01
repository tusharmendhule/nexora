import "dotenv/config";

const required = (name, fallback = undefined) => {
  const value = process.env[name] ?? fallback;
  if (value === undefined) {
    if (name === "MONGODB_URI") {
      console.warn(
        `[env] ${name} is not set. The server will start, but database features will fail.`,
      );
    }
    return "";
  }
  return value;
};

export const env = {
  port: Number(process.env.PORT ?? 4000),
  nodeEnv: process.env.NODE_ENV ?? "development",
  corsOrigin: process.env.CORS_ORIGIN ?? "*",
  isProduction: process.env.NODE_ENV === "production",

  mongodbUri: required("MONGODB_URI"),

  // In production, a strong JWT_SECRET must be set; fail loudly instead of
  // silently shipping with the dev default.
  jwtSecret:
    process.env.NODE_ENV === "production"
      ? required("JWT_SECRET")
      : required("JWT_SECRET", "dev-secret"),

  cloudinary: {
    cloudName: required("CLOUDINARY_CLOUD_NAME"),
    apiKey: required("CLOUDINARY_API_KEY"),
    apiSecret: required("CLOUDINARY_API_SECRET"),
  },

  redisUrl: required("REDIS_URL"),

  aiServiceUrl: process.env.AI_SERVICE_URL ?? "http://localhost:8000",
};
