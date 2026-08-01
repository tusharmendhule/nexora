import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import { env } from "./config/env.js";
import routes from "./routes/index.js";
import { notFound, errorHandler } from "./middleware/error.middleware.js";

const app = express();

app.use(helmet());
app.use(cors({ origin: env.corsOrigin }));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));
if (env.nodeEnv !== "test") app.use(morgan("dev"));

app.use("/api/v1", routes);

app.use(notFound);
app.use(errorHandler);

export default app;
