import multer from "multer";

const ALLOWED_MIME = new Set([
  // Images
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  // Videos
  "video/mp4",
  "video/webm",
  "video/quicktime",
]);

const AVATAR_MIME = new Set(["image/jpeg", "image/png", "image/webp"]);

const IMAGE_VIDEO_MAX = 20 * 1024 * 1024; // 20 MB per file
const AVATAR_MAX = 5 * 1024 * 1024; // 5 MB

function fileFilter(allowed) {
  return (req, file, cb) => {
    if (allowed.has(file.mimetype)) return cb(null, true);
    const err = new Error("Unsupported file type");
    err.status = 400;
    return cb(err);
  };
}

/** Multipart upload for post media (max 10 files, images + videos). */
export const uploadMedia = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: IMAGE_VIDEO_MAX, files: 10 },
  fileFilter: fileFilter(ALLOWED_MIME),
});

/** Single image upload for avatars / stories. */
export const uploadImage = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: AVATAR_MAX, files: 1 },
  fileFilter: fileFilter(AVATAR_MIME),
});
