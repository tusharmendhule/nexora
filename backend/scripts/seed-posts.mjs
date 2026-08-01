// Seed 200 additional realistic posts (with trust results + checks) into the
// existing Nexora database. Additive — nothing is wiped. Existing users are
// reused; if fewer than 3 users exist, a handful are created.
//
// Run from the backend/ directory:
//
//   node scripts/seed-posts.mjs [count]
//
// (defaults to 200 posts)
import "dotenv/config";
import mongoose from "mongoose";
import { hashPassword } from "../src/utils/password.js";

const COUNT = Math.min(Number(process.argv[2] ?? 200) || 200, 1000);
const IMG = (seed) => `https://picsum.photos/seed/${seed}/800/1000`;
const VIDEO = "https://flutter.github.io/assets-for-api-assets/docs/videos/bee.mp4";
const PASSWORD = "nexora123";

// A pool of realistic captions so the 200 posts feel like a real feed.
const CAPTION_POOL = [
  "Golden hour walk 🍂 #goldenhour",
  "Coffee first, everything else later ☕ #morningroutine",
  "New recipe test — results tomorrow 🍜 #cooking",
  "The city never sleeps. #urban #night",
  "Backend deploy at 3am. Zero downtime. 🚀 #devlife",
  "This view never gets old. #travel",
  "Weekend project: building a trust-first community 🤝 #buildinpublic",
  "Just finished a 10k run 🏃 #fitness",
  "Sunday reset — cleaning the desk, clearing the mind. #productivity",
  "Sunset from the pier. No filter. #photography",
  "Reading week! 📚 #books",
  "New studio setup is finally done 🎧 #music",
  "Farmers market haul 🥑 #foodie",
  "Morning pages. Every day. #journaling",
  "The team shipped v2 today. Proud moment. #startup",
  "Trail run at dawn — worth the 5am alarm. #hiking",
  "Rainy day playlist. Link in bio. 🎶 #playlist",
  "Learning Rust, slowly but surely. 🦀 #coding",
  "Sourdough attempt #12 — actually edible this time! 🍞 #baking",
  "Sketching in the park. #art",
  "Big announcement coming next week… stay tuned 👀",
  "One year on Nexora! Here's to the community 🥂 #anniversary",
  "Cycled 30km along the coast today 🚴 #cycling",
  "Night market finds 🌙 #streetfood",
  "Mentoring session with the junior devs — so proud. #tech",
  "The garden is blooming 🌻 #plants",
  "Tested the new camera — portraits are stunning. #photography",
  "Chai and a good book. Perfect evening. ☕📖 #chai",
  "Just donated blood. Takes 10 minutes, saves lives. ❤️",
  "My desk setup tour — link in bio. #setup",
  "Exploring the old town alleys 🏛️ #history",
  "Fresh bread smell is the best alarm clock. 🥖 #baking",
  "Hackathon weekend — 36 hours, 0 sleep, 1 working prototype 💻",
  "The ocean at sunset. Need I say more? 🌊 #beach",
  "Small wins: finally fixed that memory leak. #coding",
  "Market day! Fresh flowers for the kitchen table 💐",
  "Practicing guitar — day 47. Getting there. 🎸",
  "Cloud watching from the rooftop ☁️ #slowliving",
  "Packed lunch: rice, greens, and a happy heart. 🍱",
  "Museum day with the family 🖼️ #culture",
];

const HASHTAG_POOL = [
  "goldenhour", "photography", "cooking", "fitness", "devlife", "travel",
  "music", "art", "books", "startup", "nature", "streetfood", "coding",
  "productivity", "citylife", "weekendvibes", "morningroutine", "foodie",
];

const SEVERITY = [
  { label: "Verified", min: 82, level: "verified", checks: [] },
  { label: "Vetted", min: 65, level: "verified", checks: [] },
  { label: "Watch", min: 45, level: "flagged", checks: ["fakeNews", "clickbait"] },
  { label: "Restricted", min: 25, level: "flagged", checks: ["hateSpeech", "offensiveContent"] },
];

function rand(list) {
  return list[Math.floor(Math.random() * list.length)];
}

function pickTags() {
  const tags = new Set();
  const n = 1 + Math.floor(Math.random() * 3);
  for (let i = 0; i < n; i++) tags.add(rand(HASHTAG_POOL));
  return [...tags];
}

/** Build the six-check payload in the exact shape the AI service emits. */
function buildChecks(severity) {
  const all = [
    { name: "fakeNews", label: "Fake news" },
    { name: "hateSpeech", label: "Hate speech" },
    { name: "toxicLanguage", label: "Toxic language" },
    { name: "clickbait", label: "Clickbait" },
    { name: "spam", label: "Spam" },
    { name: "offensiveContent", label: "Offensive content" },
  ];
  return all.map((c) => {
    const flagged = severity.checks.includes(c.name);
    return {
      name: c.name,
      label: c.label,
      score: flagged ? 68 + Math.floor(Math.random() * 30) : Math.floor(Math.random() * 12),
      level: flagged ? "high" : "none",
      flags: flagged ? ["sample signal"] : [],
      detail: flagged ? `${c.label} signal detected` : "no signals found",
    };
  });
}

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error("MONGODB_URI not set in .env — run from backend/ directory.");
    process.exit(1);
  }

  await mongoose.connect(uri);
  const db = mongoose.connection.db;

  // Reuse existing users; create a few if the DB is nearly empty.
  let userIds = (await db.collection("users").find({}, { projection: { _id: 1 } }).toArray()).map(
    (u) => u._id,
  );
  if (userIds.length < 3) {
    console.log(`Only ${userIds.length} users found — creating demo users…`);
    const { insertedIds } = await db.collection("users").insertMany([
      { email: "seed1@nexora.test", passwordHash: hashPassword(PASSWORD), name: "Seed One", username: "seedone", trustScore: 80, trustLabel: "Verified", isVerified: true },
      { email: "seed2@nexora.test", passwordHash: hashPassword(PASSWORD), name: "Seed Two", username: "seedtwo", trustScore: 66, trustLabel: "Vetted" },
      { email: "seed3@nexora.test", passwordHash: hashPassword(PASSWORD), name: "Seed Three", username: "seedthree", trustScore: 50, trustLabel: "Watch" },
    ]);
    userIds = Object.values(insertedIds);
  }

  const now = Date.now();
  const postsToInsert = [];
  const trustToInsert = [];

  for (let i = 0; i < COUNT; i++) {
    const author = rand(userIds);
    const severity = rand(SEVERITY);
    const score = severity.min + Math.floor(Math.random() * (100 - severity.min));
    const hasVideo = i % 7 === 0;
    const media = hasVideo
      ? [{ url: VIDEO, type: "video", publicId: "" }]
      : [
          { url: IMG(`seed-${i}a`), type: "image", publicId: "" },
          ...(i % 5 === 0 ? [{ url: IMG(`seed-${i}b`), type: "image", publicId: "" }] : []),
        ];
    const createdAt = new Date(now - i * 1000 * 60 * 37 - Math.floor(Math.random() * 3600e3));

    const { insertedId } = await db.collection("posts").insertOne({
      author,
      caption: rand(CAPTION_POOL),
      media,
      hashtags: pickTags(),
      mentions: [],
      location: "",
      likesCount: Math.floor(Math.random() * 900) + 5,
      commentsCount: Math.floor(Math.random() * 60),
      sharesCount: Math.floor(Math.random() * 40),
      trustCheck: {
        status: severity.level,
        score,
        evidence: severity.level === "verified" ? "AI content review passed" : "AI content review flagged",
      },
      moderationStatus: "visible",
      createdAt,
    });
    postsToInsert.push(insertedId);

    trustToInsert.push({
      post: insertedId,
      userId: author,
      score,
      label: severity.label,
      factors: [
        { name: "content", value: score / 100, detail: "content analysis" },
        { name: "source", value: 0.8, detail: "author trust history" },
      ],
      checks: buildChecks(severity),
      factChecks: [],
      createdAt,
    });
  }

  // Batch insert trust results in chunks (200 docs at a time).
  for (let i = 0; i < trustToInsert.length; i += 200) {
    await db.collection("trustresults").insertMany(trustToInsert.slice(i, i + 200));
  }

  // Sprinkle a few comments + likes on the newest posts.
  const newest = postsToInsert.slice(0, Math.min(40, postsToInsert.length));
  const commentTexts = ["Love this! ❤️", "Great post!", "This is the content we need.", "🔥", "Couldn't agree more.", "New here — following!", "Beautiful.", "Thanks for sharing!"];
  const comments = [];
  for (let i = 0; i < newest.length; i++) {
    comments.push({
      post: newest[i],
      author: rand(userIds),
      text: rand(commentTexts),
      likes: Math.floor(Math.random() * 20),
      createdAt: new Date(now - i * 1000 * 60 * 11),
    });
  }
  await db.collection("comments").insertMany(comments);

  const postCount = await db.collection("posts").countDocuments();
  const trustCount = await db.collection("trustresults").countDocuments();
  console.log(`✓ Seeded ${COUNT} posts.`);
  console.log(`  posts: ${postCount}`);
  console.log(`  trustresults: ${trustCount}`);
  console.log(`  comments: ${await db.collection("comments").countDocuments()}`);

  await mongoose.disconnect();
  process.exit(0);
}

main().catch((err) => {
  console.error("✗ Seed failed:", err);
  process.exit(1);
});
