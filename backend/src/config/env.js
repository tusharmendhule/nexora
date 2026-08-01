import "dotenv/config";

const required = (name, fallback = undefined) => {
  const value = process.env[name] ?? fallback;
  if (value === undefined) {
    // Only hard-fail on the truly essential value at startup.
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

  mongodbUri: required("MONGODB_URI"),

  jwtSecret: required("JWT_SECRET", "dev-secret"),
  firebase: {
    projectId: required("FIREBASE_PROJECT_ID"),
    clientEmail: required("FIREBASE_CLIENT_EMAIL"),
    privateKey: (process.env.FIREBASE_PRIVATE_KEY ?? "").replace(/\\n/g, "\n"),
  },

  cloudinary: {
    cloudName: required("CLOUDINARY_CLOUD_NAME"),
    apiKey: required("CLOUDINARY_API_KEY"),
    apiSecret: required("CLOUDINARY_API_SECRET"),
  },

  redisUrl: required("REDIS_URL"),

  aiServiceUrl: process.env.AI_SERVICE_URL ?? "http://localhost:8000",

  factCheckApiKey: required("GOOGLE_FACTCHECK_API_KEY"),
};
