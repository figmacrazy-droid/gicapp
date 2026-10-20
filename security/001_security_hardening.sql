-- ==============================================================================
-- 🛡️ GIC — Security hardening migration
-- ------------------------------------------------------------------------------
-- * Control panel  -> Supabase Auth (JWT). Writes allowed only for active admins.
-- * Student app    -> server-side sessions (opaque token) + SECURITY DEFINER RPCs.
-- * Student passwords hashed with bcrypt (automatic trigger, Excel import keeps working).
-- * Server-side brute-force throttling for student logins.
-- Idempotent: safe to run more than once.
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- ------------------------------------------------------------------------------
-- 1. Admin users (linked 1:1 with auth.users) + audit logs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'employee' CHECK (role IN ('super_admin', 'employee')),
    phone TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    username TEXT NOT NULL,
    full_name TEXT NOT NULL,
    action_type TEXT NOT NULL,
    module TEXT NOT NULL,
    target_service TEXT,
    description TEXT NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);

-- Role helpers (SECURITY DEFINER so they can read admin_users regardless of RLS)
CREATE OR REPLACE FUNCTION public.is_active_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.admin_users WHERE id = auth.uid() AND is_active);
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.admin_users WHERE id = auth.uid() AND is_active AND role = 'super_admin');
$$;

-- Prevent non-super admins from escalating their own role / permissions,
-- and stop a super admin from locking himself out.
CREATE OR REPLACE FUNCTION public.guard_admin_users()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF; -- service role / SQL editor
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.id = auth.uid() AND (NEW.role <> 'super_admin' OR NEW.is_active = FALSE) THEN
    RAISE EXCEPTION 'لا يمكن للمدير العام تعطيل حسابه أو إزالة صلاحياته بنفسه';
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_guard_admin_users ON public.admin_users;
CREATE TRIGGER trg_guard_admin_users BEFORE UPDATE ON public.admin_users
FOR EACH ROW EXECUTE FUNCTION public.guard_admin_users();

-- Audit log rows are always stamped with the real caller identity
CREATE OR REPLACE FUNCTION public.stamp_audit_log()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE a public.admin_users%ROWTYPE;
BEGIN
  IF auth.uid() IS NOT NULL THEN
    SELECT * INTO a FROM public.admin_users WHERE id = auth.uid();
    NEW.user_id := a.id;
    NEW.username := COALESCE(a.username, NEW.username);
    NEW.full_name := COALESCE(a.full_name, NEW.full_name);
  END IF;
  NEW.created_at := NOW();
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_stamp_audit_log ON public.audit_logs;
CREATE TRIGGER trg_stamp_audit_log BEFORE INSERT ON public.audit_logs
FOR EACH ROW EXECUTE FUNCTION public.stamp_audit_log();

-- ------------------------------------------------------------------------------
-- 2. Student password hashing (bcrypt) — transparent for the control panel
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.hash_student_password()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
BEGIN
  IF NEW.password IS NOT NULL AND NEW.password !~ '^(\$2[aby]\$|gic\$v1\$)' THEN
    NEW.password := extensions.crypt(btrim(NEW.password), extensions.gen_salt('bf', 8));
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_hash_student_password ON public.students;
CREATE TRIGGER trg_hash_student_password BEFORE INSERT OR UPDATE OF password ON public.students
FOR EACH ROW EXECUTE FUNCTION public.hash_student_password();

-- hash all existing plaintext passwords
UPDATE public.students SET password = password WHERE password !~ '^(\$2[aby]\$|gic\$v1\$)';

-- ------------------------------------------------------------------------------
-- 3. Student sessions / throttling / per-student read receipts
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_sessions (
    token_hash TEXT PRIMARY KEY,
    academic_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_student_sessions_academic ON public.student_sessions(academic_id);

CREATE TABLE IF NOT EXISTS public.student_login_attempts (
    academic_id TEXT PRIMARY KEY,
    fail_count INT NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.notification_reads (
    academic_id TEXT NOT NULL,
    notification_id TEXT NOT NULL,
    read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (academic_id, notification_id)
);

-- ------------------------------------------------------------------------------
-- 4. Student RPCs (the ONLY way the mobile app touches private data)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._student_profile(p_id TEXT)
RETURNS JSONB LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT to_jsonb(s) - 'password' - 'failed_attempts' - 'locked_until'
  FROM public.students s WHERE s.academic_id = p_id;
$$;

CREATE OR REPLACE FUNCTION public._session_student(p_token TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_id TEXT;
BEGIN
  IF p_token IS NULL OR length(p_token) < 32 THEN RAISE EXCEPTION 'INVALID_SESSION'; END IF;
  UPDATE public.student_sessions ss
     SET last_used_at = NOW()
   WHERE ss.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
     AND ss.expires_at > NOW()
  RETURNING ss.academic_id INTO v_id;
  IF v_id IS NULL THEN RAISE EXCEPTION 'INVALID_SESSION'; END IF;
  IF EXISTS (SELECT 1 FROM public.students WHERE academic_id = v_id AND COALESCE(is_blocked, FALSE)) THEN
    RAISE EXCEPTION 'ACCOUNT_BLOCKED';
  END IF;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.app_login(p_academic_id TEXT, p_password TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE
  v_id TEXT := btrim(COALESCE(p_academic_id, ''));
  v_pass TEXT := btrim(COALESCE(p_password, ''));
  v_att public.student_login_attempts%ROWTYPE;
  v_stu public.students%ROWTYPE;
  v_fails INT;
  v_lock TIMESTAMPTZ;
  v_token TEXT;
BEGIN
  IF v_id !~ '^\d{10}$' OR v_pass = '' THEN
    RETURN jsonb_build_object('status', 'invalid');
  END IF;

  SELECT * INTO v_att FROM public.student_login_attempts WHERE academic_id = v_id;
  IF v_att.locked_until IS NOT NULL AND v_att.locked_until > NOW() THEN
    RETURN jsonb_build_object('status', 'locked',
      'seconds', CEIL(EXTRACT(EPOCH FROM (v_att.locked_until - NOW())))::INT);
  END IF;

  SELECT * INTO v_stu FROM public.students WHERE academic_id = v_id;

  IF v_stu.academic_id IS NULL OR v_stu.password IS NULL
     OR extensions.crypt(v_pass, v_stu.password) <> v_stu.password THEN
    v_fails := COALESCE(v_att.fail_count, 0) + 1;
    v_lock := CASE
      WHEN v_fails >= 9 AND v_fails % 3 = 0 THEN NOW() + INTERVAL '24 hours'
      WHEN v_fails = 6 THEN NOW() + INTERVAL '1 hour'
      WHEN v_fails = 3 THEN NOW() + INTERVAL '1 minute'
      ELSE NULL END;
    INSERT INTO public.student_login_attempts AS a (academic_id, fail_count, locked_until, updated_at)
    VALUES (v_id, v_fails, v_lock, NOW())
    ON CONFLICT (academic_id) DO UPDATE SET fail_count = EXCLUDED.fail_count,
      locked_until = EXCLUDED.locked_until, updated_at = NOW();
    IF v_lock IS NOT NULL THEN
      RETURN jsonb_build_object('status', 'locked',
        'seconds', CEIL(EXTRACT(EPOCH FROM (v_lock - NOW())))::INT, 'attempts', v_fails);
    END IF;
    RETURN jsonb_build_object('status', 'invalid', 'attempts', v_fails,
      'remaining', 3 - (v_fails % 3));
  END IF;

  DELETE FROM public.student_login_attempts WHERE academic_id = v_id;

  IF COALESCE(v_stu.is_blocked, FALSE) THEN
    RETURN jsonb_build_object('status', 'blocked');
  END IF;

  v_token := encode(extensions.gen_random_bytes(32), 'hex');
  DELETE FROM public.student_sessions WHERE academic_id = v_id AND expires_at < NOW();
  INSERT INTO public.student_sessions (token_hash, academic_id, expires_at)
  VALUES (encode(extensions.digest(v_token, 'sha256'), 'hex'), v_id, NOW() + INTERVAL '365 days');

  RETURN jsonb_build_object('status', 'ok', 'token', v_token, 'profile', public._student_profile(v_id));
END $$;

CREATE OR REPLACE FUNCTION public.app_session_status(p_token TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id TEXT;
BEGIN
  BEGIN
    v_id := public._session_student(p_token);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = 'ACCOUNT_BLOCKED' THEN RETURN jsonb_build_object('status', 'blocked'); END IF;
    RETURN jsonb_build_object('status', 'invalid');
  END;
  RETURN jsonb_build_object('status', 'ok', 'profile', public._student_profile(v_id));
END $$;

CREATE OR REPLACE FUNCTION public.app_logout(p_token TEXT)
RETURNS VOID LANGUAGE sql SECURITY DEFINER SET search_path = public, extensions AS $$
  DELETE FROM public.student_sessions
  WHERE token_hash = encode(extensions.digest(COALESCE(p_token, ''), 'sha256'), 'hex');
$$;

CREATE OR REPLACE FUNCTION public.app_change_password(p_token TEXT, p_old TEXT, p_new TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_id TEXT := public._session_student(p_token); v_hash TEXT;
BEGIN
  IF length(btrim(COALESCE(p_new, ''))) < 6 THEN
    RETURN jsonb_build_object('status', 'weak');
  END IF;
  SELECT password INTO v_hash FROM public.students WHERE academic_id = v_id;
  IF v_hash IS NULL OR extensions.crypt(btrim(COALESCE(p_old, '')), v_hash) <> v_hash THEN
    RETURN jsonb_build_object('status', 'wrong_old');
  END IF;
  UPDATE public.students SET password = btrim(p_new) WHERE academic_id = v_id; -- trigger hashes it
  -- log out every other device
  DELETE FROM public.student_sessions
   WHERE academic_id = v_id AND token_hash <> encode(extensions.digest(p_token, 'sha256'), 'hex');
  RETURN jsonb_build_object('status', 'ok');
END $$;

CREATE OR REPLACE FUNCTION public.app_get_result(p_token TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id TEXT := public._session_student(p_token); v_profile JSONB; v_res JSONB;
BEGIN
  v_profile := public._student_profile(v_id);
  SELECT to_jsonb(r) INTO v_res FROM public.student_results r WHERE r.academic_id = v_id;
  IF v_res IS NOT NULL THEN
    v_res := v_res || jsonb_build_object('students', v_profile);
  END IF;
  RETURN jsonb_build_object('result', v_res, 'student', v_profile);
END $$;

CREATE OR REPLACE FUNCTION public.app_get_seating(p_token TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id TEXT := public._session_student(p_token); v_row JSONB;
BEGIN
  SELECT to_jsonb(sn) INTO v_row FROM public.seating_numbers sn WHERE sn.academic_id = v_id;
  IF v_row IS NULL THEN RETURN NULL; END IF;
  RETURN v_row || jsonb_build_object('students', public._student_profile(v_id));
END $$;

CREATE OR REPLACE FUNCTION public.app_get_finance(p_token TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id TEXT := public._session_student(p_token);
BEGIN
  RETURN COALESCE((
    SELECT jsonb_agg(to_jsonb(f) ORDER BY f.created_at DESC)
    FROM public.finance_notifications f
    WHERE f.academic_id::TEXT = v_id OR f.academic_id IS NULL
  ), '[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public._is_public_target(p_target TEXT)
RETURNS BOOLEAN LANGUAGE sql IMMUTABLE AS $$
  SELECT p_target IS NULL OR btrim(p_target) = '' OR lower(btrim(p_target)) = 'all';
$$;

CREATE OR REPLACE FUNCTION public.app_get_notifications(p_token TEXT, p_unread_only BOOLEAN DEFAULT FALSE, p_limit INT DEFAULT 300)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id TEXT := public._session_student(p_token);
BEGIN
  RETURN COALESCE((
    SELECT jsonb_agg(x.j ORDER BY x.created_at DESC) FROM (
      SELECT n.created_at,
             to_jsonb(n) || jsonb_build_object('is_read',
               CASE WHEN public._is_public_target(n.academic_id::TEXT)
                    THEN EXISTS (SELECT 1 FROM public.notification_reads nr
                                 WHERE nr.academic_id = v_id AND nr.notification_id = n.id::TEXT)
                    ELSE COALESCE(n.is_read, FALSE) END) AS j
      FROM public.notifications n
      WHERE n.academic_id::TEXT = v_id OR public._is_public_target(n.academic_id::TEXT)
      ORDER BY n.created_at DESC
      LIMIT LEAST(GREATEST(COALESCE(p_limit, 300), 1), 500)
    ) x
    WHERE NOT COALESCE(p_unread_only, FALSE) OR (x.j->>'is_read')::BOOLEAN = FALSE
  ), '[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public.app_mark_notifications_read(p_token TEXT, p_ids TEXT[] DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id TEXT := public._session_student(p_token);
BEGIN
  UPDATE public.notifications n SET is_read = TRUE
   WHERE n.academic_id::TEXT = v_id AND COALESCE(n.is_read, FALSE) = FALSE
     AND (p_ids IS NULL OR n.id::TEXT = ANY (p_ids));
  INSERT INTO public.notification_reads (academic_id, notification_id)
  SELECT v_id, n.id::TEXT FROM public.notifications n
   WHERE public._is_public_target(n.academic_id::TEXT)
     AND (p_ids IS NULL OR n.id::TEXT = ANY (p_ids))
  ON CONFLICT DO NOTHING;
END $$;

-- Function privileges: internal helpers are not callable from the API
REVOKE ALL ON FUNCTION public._student_profile(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._session_student(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.guard_admin_users() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.stamp_audit_log() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.hash_student_password() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.app_login(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.app_session_status(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.app_logout(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.app_change_password(TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.app_get_result(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.app_get_seating(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.app_get_finance(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.app_get_notifications(TEXT, BOOLEAN, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.app_mark_notifications_read(TEXT, TEXT[]) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_active_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

-- ------------------------------------------------------------------------------
-- 5. Row Level Security — drop every old (permissive) policy and rebuild
-- ------------------------------------------------------------------------------
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', r.tablename);
  END LOOP;
END $$;

DO $$
DECLARE
  t TEXT;
  public_content TEXT[] := ARRAY['system_instructions','academic_staff','schedules','top_students',
    'calendar_events','social_media_links','achievements','alumni_batches','university_guides',
    'ad_banners','specialties'];
  special TEXT[] := ARRAY['admin_users','audit_logs','notifications'];
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    IF t = ANY (special) THEN CONTINUE; END IF;
    -- every table: full access for active admins of the control panel
    EXECUTE format('CREATE POLICY "admin_all" ON public.%I FOR ALL TO authenticated
                    USING (public.is_active_admin()) WITH CHECK (public.is_active_admin())', t);
    -- public read-only content for the student app
    IF t = ANY (public_content) THEN
      EXECUTE format('CREATE POLICY "public_read" ON public.%I FOR SELECT TO anon, authenticated USING (true)', t);
    END IF;
  END LOOP;
END $$;

-- notifications: admins full access; app (anon) may read ONLY broadcast rows (needed for Realtime)
CREATE POLICY "admin_all" ON public.notifications FOR ALL TO authenticated
  USING (public.is_active_admin()) WITH CHECK (public.is_active_admin());
CREATE POLICY "public_broadcast_read" ON public.notifications FOR SELECT TO anon
  USING (public._is_public_target(academic_id::TEXT));

-- admin_users: each admin sees himself; only super admin manages others
CREATE POLICY "self_or_super_read" ON public.admin_users FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_super_admin());
CREATE POLICY "super_insert" ON public.admin_users FOR INSERT TO authenticated
  WITH CHECK (public.is_super_admin());
CREATE POLICY "super_update" ON public.admin_users FOR UPDATE TO authenticated
  USING (public.is_super_admin()) WITH CHECK (public.is_super_admin());
CREATE POLICY "super_delete" ON public.admin_users FOR DELETE TO authenticated
  USING (public.is_super_admin() AND id <> auth.uid());

-- audit_logs: append-only for admins, readable by super admin, never editable
CREATE POLICY "admin_insert" ON public.audit_logs FOR INSERT TO authenticated
  WITH CHECK (public.is_active_admin());
CREATE POLICY "super_read" ON public.audit_logs FOR SELECT TO authenticated
  USING (public.is_super_admin());

GRANT EXECUTE ON FUNCTION public._is_public_target(TEXT) TO anon, authenticated;
