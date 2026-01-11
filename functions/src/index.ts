import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

admin.initializeApp();

const key = process.env.MAPS_KEY;

interface DirectionsResponse {
  status: string;
  routes: Array<{
    overview_polyline: { points: string };
  }>;
  error_message?: string;
}

/**
 * ✅ HTTP v1 (gratis): Directions
 */
export const directions = functions.https.onRequest(async (req, res) => {
  try {
    const origin = String(req.query.origin ?? "");
    const destination = String(req.query.destination ?? "");
    const mode = String(req.query.mode ?? "driving");

    if (!origin || !destination) {
      res.status(400).json({ error: "Origin and destination are required" });
      return;
    }

    if (!key) {
      res.status(500).json({ error: "API key not configured" });
      return;
    }

    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(
      origin
    )}&destination=${encodeURIComponent(destination)}&mode=${encodeURIComponent(
      mode
    )}&key=${key}`;

    const response = await fetch(url);
    const data = (await response.json()) as DirectionsResponse;

    if (data.status !== "OK") {
      res.status(400).json({ error: data.status, message: data.error_message });
      return;
    }

    const points = decodePolyline(data.routes[0].overview_polyline.points);
    res.json({ points });
  } catch (e: any) {
    res.status(500).json({ error: e?.message ?? String(e) });
  }
});

function decodePolyline(encoded: string): Array<{ lat: number; lng: number }> {
  let index = 0;
  let lat = 0;
  let lng = 0;
  const coordinates: Array<{ lat: number; lng: number }> = [];

  while (index < encoded.length) {
    let b: number;
    let shift = 0;
    let result = 0;

    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);

    const dlat = (result & 1) ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;

    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);

    const dlng = (result & 1) ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    coordinates.push({ lat: lat / 1e5, lng: lng / 1e5 });
  }

  return coordinates;
}

/**
 * ✅ Callable v1 (gratis): setUserRole
 * Requiere que el que llame sea admin (custom claim admin: true)
 */
export const setUserRole = functions.https.onCall(async (data: any, context: any) => {
  if (!context.auth || context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can set roles."
    );
  }

  const email = String(data?.email ?? "").toLowerCase().trim();
  const role = String(data?.role ?? "").trim(); // admin | staff | worker

  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Missing email.");
  }

  if (!["admin", "staff", "worker"].includes(role)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "role must be admin | staff | worker"
    );
  }

  const user = await admin.auth().getUserByEmail(email);

  await admin.auth().setCustomUserClaims(user.uid, {
    role,
    admin: role === "admin",
    staff: role === "staff",
    worker: role === "worker",
  });

  await admin.firestore().collection("users").doc(user.uid).set(
    {
      email,
      role,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { ok: true, uid: user.uid, role };
});

