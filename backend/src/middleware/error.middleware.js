/** 404 fallback for unknown routes. */
export function notFound(req, res) {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
}

/** Centralized error handler. */
export function errorHandler(err, req, res, _next) {
  console.error("[error]", err.message);
  if (err.name === "ValidationError") {
    return res.status(400).json({ error: err.message });
  }
  if (err.code === 11000) {
    return res.status(409).json({ error: "Duplicate key error" });
  }
  const status = err.status ?? 500;
  res.status(status).json({
    error: status >= 500 ? "Internal server error" : err.message,
  });
}
