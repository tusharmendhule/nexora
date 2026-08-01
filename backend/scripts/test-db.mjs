// Throwaway connectivity test: connects to MongoDB Atlas via the backend env,
// inserts a document, reads it back, then removes it (and drops the test
// collection) so no artifacts remain. Run from the backend/ directory:
//
//   node scripts/test-db.mjs
//
// (dotenv loads .env relative to the current working directory.)
import "dotenv/config";
import mongoose from "mongoose";

const uri = process.env.MONGODB_URI;
if (!uri) {
  console.error("MONGODB_URI is not set in .env — run from the backend/ directory.");
  process.exit(1);
}

let insertedId = null;
let coll = null;

try {
  await mongoose.connect(uri);
  console.log("✓ connected to MongoDB Atlas");

  coll = mongoose.connection.db.collection("_connectivity_test");

  // Insert
  const { insertedId: id } = await coll.insertOne({
    marker: "nexora-test",
    at: new Date(),
  });
  insertedId = id;
  console.log("✓ insert ok ->", id.toString());

  // Read
  const doc = await coll.findOne({ _id: id });
  console.log("✓ read ok ->", doc ? "document found" : "MISSING");

  // Show available collections (sanity)
  const collections = (await mongoose.connection.db.listCollections().toArray()).map(
    (c) => c.name,
  );
  console.log("collections:", collections.join(", ") || "(none yet)");

  console.log("ALL TESTS PASSED");
} catch (err) {
  console.error("✗ TEST FAILED:", err.message);
  process.exitCode = 1;
} finally {
  // Guaranteed cleanup: never leave test documents or collections in Atlas.
  try {
    if (insertedId && coll) await coll.deleteOne({ _id: insertedId });
    if (coll) await coll.drop().catch(() => {});
    console.log("✓ cleanup ok (document removed, collection dropped)");
  } catch (cleanupErr) {
    console.warn("⚠ cleanup warning:", cleanupErr.message);
  }
  await mongoose.disconnect();
}
