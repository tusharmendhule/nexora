import cloudinary from "cloudinary";
import { env } from "../config/env.js";

const configured = Boolean(
  env.cloudinary.cloudName &&
    env.cloudinary.apiKey &&
    env.cloudinary.apiSecret,
);

if (configured) {
  cloudinary.v2.config({
    cloud_name: env.cloudinary.cloudName,
    api_key: env.cloudinary.apiKey,
    api_secret: env.cloudinary.apiSecret,
  });
}

export const media = {
  /**
   * Upload a file buffer to Cloudinary.
   * Falls back to returning the original buffer metadata when unconfigured
   * so local development still works without credentials.
   */
  async upload({ buffer, folder = "nexora", resourceType = "auto" }) {
    if (!configured) {
      return {
        url: "",
        publicId: "",
        fallback: true,
        size: buffer.length,
      };
    }
    const result = await new Promise((resolve, reject) => {
      const stream = cloudinary.v2.uploader.upload_stream(
        { folder, resource_type: resourceType },
        (error, result) => (error ? reject(error) : resolve(result)),
      );
      stream.end(buffer);
    });
    return { url: result.secure_url, publicId: result.public_id };
  },

  async delete(publicId) {
    if (!configured || !publicId) return;
    await cloudinary.v2.uploader.destroy(publicId).catch(() => {});
  },
};
