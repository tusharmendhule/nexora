import { Server } from "socket.io";
import jwt from "jsonwebtoken";
import { env } from "../config/env.js";

let io = null;

/**
 * Attach Socket.IO to the running HTTP server.
 * - Authenticates every socket via the access token in the handshake.
 * - Joins each user to a private room (`user:<id>`) so we can push
 *   notifications/messages without clients polling.
 */
export function initSocket(httpServer) {
  io = new Server(httpServer, {
    cors: { origin: env.corsOrigin.split(",").map((s) => s.trim()) },
  });

  io.use((socket, next) => {
    const token =
      socket.handshake.auth?.token ??
      socket.handshake.headers?.authorization?.replace(/^Bearer\s+/i, "");
    if (!token) return next(new Error("Authentication required"));
    try {
      const payload = jwt.verify(token, env.jwtSecret);
      if (payload.type !== "access") return next(new Error("Invalid token type"));
      socket.userId = payload.sub;
      next();
    } catch {
      next(new Error("Invalid or expired token"));
    }
  });

  io.on("connection", (socket) => {
    if (!socket.userId) return socket.disconnect(true);
    socket.join(`user:${socket.userId}`);

    socket.on("disconnect", () => {
      // Socket.IO cleans up rooms automatically on disconnect.
    });
  });

  return io;
}

export function getIO() {
  return io;
}

/** Push a real-time event to one user's room. */
export function emitToUser(userId, event, payload) {
  if (!io) return;
  io.to(`user:${userId.toString()}`).emit(event, payload);
}

/** Broadcast to every connected client (e.g. moderation announcements). */
export function emitAll(event, payload) {
  if (!io) return;
  io.emit(event, payload);
}
