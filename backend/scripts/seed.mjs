// Seed MongoDB Atlas with realistic Nexora sample data so the API serves real
// content (feed, trust results, moderation queue, chats, notifications).
//
// Run from the backend/ directory (dotenv loads .env from the cwd):
//
//   node scripts/seed.mjs
//
// WARNING: this script clears the collections below before inserting fresh data.
import "dotenv/config";
import mongoose from "mongoose";
import { hashPassword } from "../src/utils/password.js";

const AVATARS = [
  "https://i.pravatar.cc/300?img=47",
  "https://i.pravatar.cc/300?img=12",
  "https://i.pravatar.cc/300?img=32",
  "https://i.pravatar.cc/300?img=13",
  "https://i.pravatar.cc/300?img=45",
  "https://i.pravatar.cc/300?img=59",
  "https://i.pravatar.cc/300?img=24",
  "https://i.pravatar.cc/300?img=68",
];

const IMG = (seed) => `https://picsum.photos/seed/${seed}/800/1000`;
const VIDEO = "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4";

const PASSWORD = "nexora123"; // all demo accounts share this password

const users = [
  { email: "aria@nexora.test", name: "Aria Chen", username: "ariachen", avatar: AVATARS[0], bio: "Designing trust-first communities ✨", location: "Singapore", role: "user", trustScore: 92, trustLabel: "Verified", isVerified: true, followersCount: 12400, followingCount: 320 },
  { email: "marcus@nexora.test", name: "Marcus Reid", username: "marcusreid", avatar: AVATARS[1], bio: "Journalist & fact-checker. Reporting with receipts.", location: "London", role: "moderator", trustScore: 88, trustLabel: "Verified", isVerified: true, followersCount: 8700, followingCount: 410 },
  { email: "sofia@nexora.test", name: "Sofia Alvarez", username: "sofiaa", avatar: AVATARS[2], bio: "Street photographer. Capturing the city one frame at a time 📷", location: "Mexico City", role: "user", trustScore: 76, trustLabel: "Vetted", isVerified: true, followersCount: 5400, followingCount: 260 },
  { email: "dev@nexora.test", name: "Dev Patel", username: "devpatel", avatar: AVATARS[3], bio: "Backend engineer. Automating everything.", location: "Bengaluru", role: "admin", trustScore: 84, trustLabel: "Vetted", isVerified: true, followersCount: 3200, followingCount: 180 },
  { email: "leo@nexora.test", name: "Leo Torres", username: "leot", avatar: AVATARS[4], bio: "Music producer 🎧", location: "Lagos", role: "user", trustScore: 58, trustLabel: "Watch", followersCount: 1900, followingCount: 540 },
  { email: "nina@nexora.test", name: "Nina Brooks", username: "ninab", avatar: AVATARS[5], bio: "New here. Learning the ropes.", location: "Toronto", role: "user", trustScore: 38, trustLabel: "Restricted", followersCount: 120, followingCount: 95 },
  { email: "yuki@nexora.test", name: "Yuki Tanaka", username: "yukit", avatar: AVATARS[6], bio: "Cooking, travel, and everything in between 🍜", location: "Osaka", role: "user", trustScore: 71, trustLabel: "Vetted", isVerified: true, followersCount: 2800, followingCount: 330 },
  { email: "priya@nexora.test", name: "Priya Sharma", username: "priyas", avatar: AVATARS[7], bio: "Climate scientist. Data over drama.", location: "Mumbai", role: "user", trustScore: 95, trustLabel: "Verified", isVerified: true, followersCount: 21000, followingCount: 210 },
];

const postDefs = [
  { user: 0, caption: "Morning light through the window ☀️ #goldenhour #coffee #morning", hashtags: ["goldenhour", "coffee", "morning"], likes: 1240, comments: 86, shares: 34, media: [IMG("nexora-p1a"), IMG("nexora-p1b")], trust: 92, label: "Verified", status: "verified" },
  { user: 4, caption: "Just dropped a new beat! 🎧 You won't believe this one 🚨 #music #producer #newdrop", hashtags: ["music", "producer", "newdrop"], likes: 480, comments: 42, shares: 15, media: [VIDEO], type: "video", trust: 58, label: "Watch", status: "flagged" },
  { user: 2, caption: "Golden hour on the pier. No filter needed. #photography #city #sunset", hashtags: ["photography", "city", "sunset"], likes: 2310, comments: 121, shares: 67, media: [IMG("nexora-p2")], trust: 76, label: "Vetted", status: "verified" },
  { user: 5, caption: "First post! Excited to be part of this community 🌱 #hello #newbie", hashtags: ["hello", "newbie"], likes: 89, comments: 23, shares: 2, media: [IMG("nexora-p3")], trust: 38, label: "Restricted", status: "flagged" },
  { user: 7, caption: "New climate data just published — the trend line keeps climbing. Sources in comments. #climate #science #data", hashtags: ["climate", "science", "data"], likes: 5120, comments: 340, shares: 890, media: [IMG("nexora-p4a"), IMG("nexora-p4b")], trust: 95, label: "Verified", status: "verified", evidence: "Peer-reviewed paper cited" },
  { user: 3, caption: "Deployed a new microservice today. Zero downtime. 🚀 #coding #devlife #backend", hashtags: ["coding", "devlife", "backend"], likes: 720, comments: 58, shares: 21, media: [IMG("nexora-p5")], trust: 84, label: "Vetted", status: "verified" },
  { user: 6, caption: "5-minute ramen that actually tastes incredible 🍜 Recipe: link in bio!", hashtags: ["ramen", "cooking", "recipes"], likes: 1680, comments: 97, shares: 145, media: [IMG("nexora-p6"), IMG("nexora-p7")], trust: 71, label: "Vetted", status: "verified" },
  { user: 1, caption: "⚠️ FACT CHECK: the viral 'waterfall city' video is from a VFX artist, not a real place. Full breakdown: [link]. #factcheck #misinformation", hashtags: ["factcheck", "misinformation"], likes: 9450, comments: 612, shares: 2100, media: [IMG("nexora-p8")], trust: 88, label: "Verified", status: "verified", evidence: "Verified against multiple sources" },
  { user: 0, caption: "This shocking secret about sleep will change your life 😱 #wellness #sleep #tips", hashtags: ["wellness", "sleep", "tips"], likes: 310, comments: 88, shares: 96, media: [IMG("nexora-p9")], trust: 45, label: "Watch", status: "flagged" },
  { user: 7, caption: "Thread: what the new IPCC numbers actually say (and don't say). 🧵", hashtags: ["ipcc", "climate"], likes: 3800, comments: 210, shares: 450, media: [IMG("nexora-p10")], trust: 94, label: "Verified", status: "verified" },
];

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error("MONGODB_URI not set in .env — run from backend/ directory.");
    process.exit(1);
  }

  await mongoose.connect(uri);
  const db = mongoose.connection.db;

  console.log("Connected. Clearing collections…");
  const collections = [
    "users", "posts", "trustresults", "reports", "moderationlogs",
    "comments", "likes", "bookmarks", "follows", "conversations",
    "messages", "notifications", "stories",
  ];
  for (const c of collections) {
    await db.collection(c).deleteMany({}).catch(() => {});
  }

  console.log("Inserting users…");
  const { insertedIds: userIds } = await db.collection("users").insertMany(
    users.map((u) => ({ ...u, passwordHash: hashPassword(PASSWORD) })),
  );
  const userId = Object.values(userIds);

  console.log("Inserting posts + trust results…");
  const now = Date.now();
  const postIds = [];
  for (let i = 0; i < postDefs.length; i++) {
    const def = postDefs[i];
    const { insertedId } = await db.collection("posts").insertOne({
      author: userId[def.user],
      caption: def.caption,
      media: (def.media ?? [IMG(`nexora-r${i}`)]).map((url) => ({ url, type: def.type ?? "image", publicId: "" })),
      hashtags: def.hashtags ?? [],
      mentions: [],
      location: users[def.user].location ?? "",
      likesCount: def.likes ?? 0,
      commentsCount: def.comments ?? 0,
      sharesCount: def.shares ?? 0,
      trustCheck: { status: def.status ?? "pending", score: def.trust ?? null, evidence: def.evidence ?? "" },
      moderationStatus: "visible",
      createdAt: new Date(now - i * 1000 * 60 * 60 * 5),
    });
    postIds.push(insertedId);

    await db.collection("trustresults").insertOne({
      post: insertedId,
      userId: userId[def.user],
      score: def.trust ?? 50,
      label: def.label ?? "Watch",
      factors: [
        { name: "source", value: (def.trust ?? 50) / 100, detail: "author trust history" },
        { name: "content", value: 0.8, detail: "content analysis" },
      ],
      factChecks: def.status === "verified" && def.evidence
        ? [{ publisher: "Nexora Fact Desk", title: def.evidence, url: "https://example.com/factcheck", rating: "Mostly true", checkedDate: new Date() }]
        : [],
      createdAt: new Date(now - i * 1000 * 60 * 60 * 5),
    });
  }

  console.log("Inserting comments…");
  const commentDefs = [
    [0, 2, "Absolutely stunning light 😍"],
    [0, 6, "That coffee looks perfect."],
    [2, 0, "This composition is unreal."],
    [4, 1, "Important context, thank you for posting."],
    [4, 3, "Citing the paper would help a lot."],
    [6, 7, "Trying this tonight! 🙌"],
    [7, 4, "People need to see this."],
    [8, 5, "Is this really true??"],
    [1, 0, "The drop at 0:30 though 🔥"],
    [3, 7, "Welcome to Nexora!"],
  ];
  for (let i = 0; i < commentDefs.length; i++) {
    const [postIdx, authorIdx, text] = commentDefs[i];
    await db.collection("comments").insertOne({
      post: postIds[postIdx],
      author: userId[authorIdx],
      text,
      likes: Math.floor(Math.random() * 30),
      createdAt: new Date(now - i * 1000 * 60 * 30),
    });
  }

  console.log("Inserting likes + follows…");
  for (let p = 0; p < postIds.length; p++) {
    const likers = (p * 3 + 2) % users.length;
    await db.collection("likes").insertOne({ post: postIds[p], user: userId[likers] });
  }
  // Follow web: everyone follows aria (0) & priya (7); a few others.
  await db.collection("follows").insertMany([
    { follower: userId[1], following: userId[0] },
    { follower: userId[2], following: userId[0] },
    { follower: userId[3], following: userId[0] },
    { follower: userId[4], following: userId[0] },
    { follower: userId[5], following: userId[0] },
    { follower: userId[6], following: userId[0] },
    { follower: userId[0], following: userId[7] },
    { follower: userId[2], following: userId[7] },
    { follower: userId[4], following: userId[7] },
    { follower: userId[0], following: userId[2] },
    { follower: userId[1], following: userId[2] },
    { follower: userId[7], following: userId[0] },
  ]);

  console.log("Inserting conversations + messages…");
  const { insertedId: convo1 } = await db.collection("conversations").insertOne({
    participants: [userId[0], userId[1]],
    lastMessageAt: new Date(now - 1000 * 60 * 12),
  });
  const { insertedId: convo2 } = await db.collection("conversations").insertOne({
    participants: [userId[0], userId[2]],
    lastMessageAt: new Date(now - 1000 * 60 * 40),
  });
  await db.collection("messages").insertMany([
    { conversation: convo1, sender: userId[1], text: "Hey Aria! Love the new feed design.", isRead: true, createdAt: new Date(now - 1000 * 60 * 40) },
    { conversation: convo1, sender: userId[0], text: "Thanks Marcus! The trust labels make a huge difference.", isRead: true, createdAt: new Date(now - 1000 * 60 * 30) },
    { conversation: convo1, sender: userId[1], text: "Agreed — fact-checked posts get way more engagement.", isRead: false, createdAt: new Date(now - 1000 * 60 * 12) },
    { conversation: convo2, sender: userId[2], text: "The golden hour shots from the pier are amazing 📷", isRead: true, createdAt: new Date(now - 1000 * 60 * 60) },
    { conversation: convo2, sender: userId[0], text: "Thanks! The light was perfect that evening.", isRead: false, createdAt: new Date(now - 1000 * 60 * 40) },
  ]);

  console.log("Inserting notifications…");
  await db.collection("notifications").insertMany([
    { user: userId[0], actor: userId[2], type: "like", text: "liked your post.", isRead: false, post: postIds[0], createdAt: new Date(now - 1000 * 60 * 20) },
    { user: userId[0], actor: userId[6], type: "comment", text: "commented: \"That coffee looks perfect.\"", isRead: false, post: postIds[0], createdAt: new Date(now - 1000 * 60 * 45) },
    { user: userId[0], actor: userId[1], type: "follow", text: "started following you.", isRead: true, createdAt: new Date(now - 1000 * 60 * 90) },
    { user: userId[0], type: "trust", text: "Your post's trust analysis scored 92 — Verified.", isTrustEvent: true, isRead: false, post: postIds[0], createdAt: new Date(now - 1000 * 60 * 60 * 3) },
  ]);

  console.log("Inserting stories…");
  await db.collection("stories").insertMany([
    { user: userId[1], imageUrl: IMG("story-1"), caption: "On assignment 📝", expiresAt: new Date(now + 12 * 3600e3), createdAt: new Date(now - 1000 * 60 * 10) },
    { user: userId[2], imageUrl: IMG("story-2"), caption: "Golden hour ✨", expiresAt: new Date(now + 8 * 3600e3), createdAt: new Date(now - 1000 * 60 * 30) },
    { user: userId[6], imageUrl: IMG("story-3"), caption: "Ramen time 🍜", expiresAt: new Date(now + 20 * 3600e3), createdAt: new Date(now - 1000 * 60 * 60) },
    { user: userId[7], imageUrl: IMG("story-4"), caption: "Field notes 🧵", expiresAt: new Date(now + 6 * 3600e3), createdAt: new Date(now - 1000 * 60 * 60 * 2) },
  ]);

  console.log("Inserting reports + moderation logs…");
  await db.collection("reports").insertMany([
    { reporter: userId[4], targetType: "post", targetId: postIds[1], reason: "spam", details: "Misleading headline", status: "open", createdAt: new Date(now - 2 * 3600e3) },
    { reporter: userId[0], targetType: "post", targetId: postIds[8], reason: "misinformation", details: "Exaggerated health claim", status: "open", createdAt: new Date(now - 1 * 3600e3) },
  ]);
  await db.collection("moderationlogs").insertOne({
    moderator: userId[1],
    action: "approve",
    targetType: "post",
    targetId: postIds[7],
    reason: "Verified against fact-check sources",
    createdAt: new Date(now - 3 * 3600e3),
  });

  console.log("✓ Seed complete:");
  for (const c of collections) {
    const count = await db.collection(c).countDocuments();
    if (count > 0) console.log(`  ${c}: ${count}`);
  }

  await mongoose.disconnect();
  process.exit(0);
}

main().catch((err) => {
  console.error("✗ Seed failed:", err);
  process.exit(1);
});
