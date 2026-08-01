import app from "./app.js";
import { env } from "./config/env.js";
import { connectDB } from "./config/db.js";

async function main() {
  await connectDB();
  app.listen(env.port, () => {
    console.log(`[server] Nexora API listening on http://localhost:${env.port}`);
    console.log(`[server] Health check: http://localhost:${env.port}/api/v1/health`);
  });
}

main().catch((err) => {
  console.error("[server] failed to start:", err);
  process.exit(1);
});
