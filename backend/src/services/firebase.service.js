import { env } from "../config/env.js";

let firebaseApp = null;

/**
 * Lazily initialize firebase-admin when FIREBASE_* credentials are configured.
 * Returns null when not configured (dev mode → local JWT auth is used instead).
 */
export async function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;
  const { projectId, clientEmail, privateKey } = env.firebase;
  if (!projectId || !clientEmail || !privateKey) return null;
  const { initializeApp, cert } = await import("firebase-admin");
  firebaseApp = initializeApp({
    credential: cert({ projectId, clientEmail, privateKey }),
  });
  return firebaseApp;
}

/**
 * Verify a Firebase ID token and return its decoded claims.
 * Throws an Error (with a `status`) when Firebase isn't configured.
 */
export async function verifyIdToken(idToken) {
  const app = await getFirebaseApp();
  if (!app) {
    const err = new Error(
      "Firebase is not configured. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY.",
    );
    err.status = 503;
    throw err;
  }
  const { getAuth } = await import("firebase-admin");
  return getAuth(app).verifyIdToken(idToken);
}

/** True when Firebase Admin is configured server-side. */
export async function isFirebaseConfigured() {
  return (await getFirebaseApp()) !== null;
}
