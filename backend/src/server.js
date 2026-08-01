import http from "http";
import app from "./app.js";
import { env } from "./config/env.js";
import { connectDB } from "./config/db.js";
import { initSocket } from "./services/socket.service.js";

async function main() {
  await connectDB();

  const server = http.createServer(app);
  initSocket(server);

  server.listen(env.port, () => {
    console.log(`[server] Nexora API listening on http://localhost:${env.port}`);
    console.log(`[server] Health check: http://localhost:${env.port}/api/v1/health`);
    console.log(`[server] Socket.IO ready on ws://localhost:${env.port}`);
  });
}

main().catch((err) => {
  console.error("[server] failed to start:", err);
  process.exit(1);
});
