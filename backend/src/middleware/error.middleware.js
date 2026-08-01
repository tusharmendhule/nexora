import mongoose from "mongoose";

/** 404 fallback for unknown routes. */
export function notFound(req, res) {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
}

/** Centralized error handler. */
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, _next) {
  console.error("[error]", err.message);

  // Mongoose validation failures.
  if (err instanceof mongoose.Error.ValidationError) {
    const first = Object.values(err.errors)[0];
    return res.status(400).json({ error: first?.message ?? "Validation failed" });
  }

  // Invalid ObjectId (e.g. malformed :id in the URL).
  if (err instanceof mongoose.Error.CastError) {
    return res.status(400).json({ error: "Invalid identifier" });
  }

  // Duplicate key (unique index violation).
  if (err.code === 11000) {
    const field = Object.keys(err.keyPattern ?? {})[0] ?? "field";
    return res.status(409).json({ error: `${field} already exists` });
  }

  // Multer upload errors (file too large / wrong type).
  if (err.name === "MulterError") {
    const msg =
      err.code === "LIMIT_FILE_SIZE"
        ? "File is too large"
        : err.code === "LIMIT_UNEXPECTED_FILE"
          ? "Unexpected file field"
          : "Upload error";
    return res.status(400).json({ error: msg });
  }

  // JSON body parse errors.
  if (err.type === "entity.too.large") {
    return res.status(413).json({ error: "Request body too large" });
  }

  const status = err.status ?? 500;
  res.status(status).json({
    error: status >= 500 ? "Internal server error" : err.message,
  });
}
