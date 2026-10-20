// Supabase Edge Function: send-push
// Sends an FCM (HTTP v1) push to a topic. Only active control-panel admins may call it.
// Secret required:  FCM_SERVICE_ACCOUNT  (full JSON of the Firebase service account)
import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

let cachedToken: { value: string; exp: number } | null = null;

async function googleAccessToken(sa: { client_email: string; private_key: string }) {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.value;
  const key = await importPKCS8(sa.private_key, "RS256");
  const assertion = await new SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  if (!res.ok) throw new Error(`google token ${res.status}: ${await res.text()}`);
  const data = await res.json();
  cachedToken = { value: data.access_token, exp: now + (data.expires_in ?? 3600) };
  return cachedToken.value;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "method not allowed" });

  try {
    // 1. Authenticate caller and make sure he is an active admin
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!jwt) return json(401, { error: "unauthorized" });
    const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
      auth: { persistSession: false },
    });
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) return json(401, { error: "unauthorized" });
    const { data: adminRow } = await admin
      .from("admin_users").select("id,is_active").eq("id", userData.user.id).maybeSingle();
    if (!adminRow?.is_active) return json(403, { error: "forbidden" });

    // 2. Validate input
    const body = await req.json().catch(() => ({}));
    const topicRaw = String(body.topic ?? "all_students");
    const title = String(body.title ?? "إشعار جديد").slice(0, 200);
    const text = String(body.body ?? "").slice(0, 2000);
    const route = String(body.routeName ?? "notifications").slice(0, 64);
    const topic = topicRaw.replace(/[^a-zA-Z0-9\-_.~%]+/g, "_");
    if (!/^(all_students|student_[A-Za-z0-9\-_.~%]{1,40})$/.test(topic)) return json(400, { error: "invalid topic" });

    // 3. Send through FCM
    const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}");
    if (!sa.client_email || !sa.private_key || !sa.project_id) return json(500, { error: "fcm not configured" });
    const token = await googleAccessToken(sa);
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({
        message: {
          topic,
          notification: { title, body: text },
          data: { title, body: text, route, click_action: "FLUTTER_NOTIFICATION_CLICK" },
          android: {
            priority: "HIGH",
            notification: {
              sound: "default",
              channel_id: "alghad_notifications_channel",
              default_sound: true,
              default_vibrate_timings: true,
            },
          },
        },
      }),
    });
    if (!res.ok) return json(502, { success: false, error: await res.text() });
    return json(200, { success: true });
  } catch (e) {
    return json(500, { success: false, error: String(e) });
  }
});
