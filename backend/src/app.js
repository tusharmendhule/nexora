import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import { env } from "./config/env.js";
import routes from "./routes/index.js";
import { notFound, errorHandler } from "./middleware/error.middleware.js";
import { apiLimiter } from "./middleware/rateLimit.middleware.js";

const app = express();

// Behind a reverse proxy (e.g. Render/Railway/Nginx) so rate limiting and
// req.ip see the real client address.
app.set("trust proxy", 1);

app.use(helmet());
app.use(cors({ origin: env.corsOrigin.split(",").map((s) => s.trim()) }));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));
if (env.nodeEnv !== "test") app.use(morgan("dev"));

// Global per-IP rate limit (auth + writes get stricter limits at the route level).
app.use("/api/v1", apiLimiter);

app.use("/api/v1", routes);

app.use(notFound);
app.use(errorHandler);

export default app;
