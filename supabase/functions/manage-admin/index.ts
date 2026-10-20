// Supabase Edge Function: manage-admin
// Create / update / delete control-panel employees (Supabase Auth user + admin_users row).
// Only an active super admin may call it.
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

const ADMIN_EMAIL_DOMAIN = "admin.gic-college.app";

/** Must match AuthService.emailForUsername() in the control panel. */
function emailForUsername(username: string): string {
  const bytes = new TextEncoder().encode(username.trim().toLowerCase());
  const hex = Array.from(bytes).map((b) => b.toString(16).padStart(2, "0")).join("");
  return `u${hex}@${ADMIN_EMAIL_DOMAIN}`;
}

function cleanUsername(v: unknown): string {
  const u = String(v ?? "").trim();
  if (u.length < 3 || new TextEncoder().encode(u.toLowerCase()).length > 30) {
    throw new Error("اسم المستخدم يجب أن يكون بين 3 و 30 حرفاً");
  }
  return u;
}

function cleanPassword(v: unknown): string {
  const p = String(v ?? "").trim();
  if (p.length < 8) throw new Error("كلمة المرور يجب ألا تقل عن 8 أحرف");
  return p;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "method not allowed" });

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  try {
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    const { data: userData } = await admin.auth.getUser(jwt);
    const callerId = userData?.user?.id;
    if (!callerId) return json(401, { error: "unauthorized" });
    const { data: caller } = await admin
      .from("admin_users").select("id,role,is_active").eq("id", callerId).maybeSingle();
    if (!caller?.is_active || caller.role !== "super_admin") return json(403, { error: "forbidden" });

    const body = await req.json().catch(() => ({}));
    const action = String(body.action ?? "");

    if (action === "create") {
      const username = cleanUsername(body.username);
      const password = cleanPassword(body.password);
      const { data: exists } = await admin.from("admin_users").select("id").ilike("username", username).maybeSingle();
      if (exists) return json(400, { error: "اسم المستخدم مستخدم مسبقاً" });

      const { data: created, error } = await admin.auth.admin.createUser({
        email: emailForUsername(username),
        password,
        email_confirm: true,
        user_metadata: { username },
      });
      if (error || !created.user) return json(400, { error: error?.message ?? "create failed" });

      const row = {
        id: created.user.id,
        username,
        full_name: String(body.full_name ?? username).trim() || username,
        role: body.role === "super_admin" ? "super_admin" : "employee",
        is_active: body.is_active !== false,
        permissions: body.role === "super_admin" ? {} : (body.permissions ?? {}),
      };
      const { error: insErr } = await admin.from("admin_users").insert(row);
      if (insErr) {
        await admin.auth.admin.deleteUser(created.user.id);
        return json(400, { error: insErr.message });
      }
      return json(200, { success: true, id: created.user.id });
    }

    if (action === "update") {
      const id = String(body.id ?? "");
      if (!id) return json(400, { error: "missing id" });
      const { data: target } = await admin.from("admin_users").select("*").eq("id", id).maybeSingle();
      if (!target) return json(404, { error: "not found" });

      const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };
      const authPatch: Record<string, unknown> = {};
      if (body.username !== undefined) {
        const username = cleanUsername(body.username);
        if (username.toLowerCase() !== String(target.username).toLowerCase()) {
          const { data: dup } = await admin.from("admin_users").select("id").ilike("username", username).maybeSingle();
          if (dup && dup.id !== id) return json(400, { error: "اسم المستخدم مستخدم مسبقاً" });
          patch.username = username;
          authPatch.email = emailForUsername(username);
          authPatch.email_confirm = true;
        }
      }
      if (body.full_name !== undefined) patch.full_name = String(body.full_name).trim() || target.full_name;
      if (body.role !== undefined) patch.role = body.role === "super_admin" ? "super_admin" : "employee";
      if (body.is_active !== undefined) patch.is_active = body.is_active === true;
      if (body.permissions !== undefined) patch.permissions = patch.role === "super_admin" ? {} : body.permissions;
      if (body.password) authPatch.password = cleanPassword(body.password);

      if (id === callerId && (patch.role === "employee" || patch.is_active === false)) {
        return json(400, { error: "لا يمكن للمدير العام تعطيل حسابه أو إزالة صلاحياته بنفسه" });
      }

      if (Object.keys(authPatch).length) {
        const { error } = await admin.auth.admin.updateUserById(id, authPatch);
        if (error) return json(400, { error: error.message });
      }
      const { error: upErr } = await admin.from("admin_users").update(patch).eq("id", id);
      if (upErr) return json(400, { error: upErr.message });
      // A disabled employee loses DB access immediately (RLS checks is_active on every request).
      return json(200, { success: true });
    }

    if (action === "delete") {
      const id = String(body.id ?? "");
      if (!id || id === callerId) return json(400, { error: "لا يمكن حذف هذا الحساب" });
      const { error } = await admin.auth.admin.deleteUser(id); // cascades to admin_users
      if (error) return json(400, { error: error.message });
      return json(200, { success: true });
    }

    return json(400, { error: "unknown action" });
  } catch (e) {
    return json(400, { error: e instanceof Error ? e.message : String(e) });
  }
});
