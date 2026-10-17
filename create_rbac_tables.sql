-- ==============================================================================
-- 🏛️ كلية الغد المشرق للعلوم الطبية والتطبيقية
-- 🛡️ سكربت إنشاء جداول إدارة وصلاحيات الموظفين وسجل الرقابة (RBAC & Audit Logs)
-- ==============================================================================

-- 1. جدول مستخدمي لوحة التحكم والموظفين (Admin Users & Employees)
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'employee' CHECK (role IN ('super_admin', 'employee')),
    phone TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. جدول سجل العمليات والرقابة (Audit Activity Logs)
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    username TEXT NOT NULL,
    full_name TEXT NOT NULL,
    action_type TEXT NOT NULL CHECK (action_type IN ('LOGIN', 'LOGOUT', 'CREATE', 'UPDATE', 'DELETE', 'STATUS_CHANGE', 'IMPORT')),
    module TEXT NOT NULL,
    target_service TEXT,
    description TEXT NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- إنشاء فهارس سريعة لتحسين أداء البحث والفلترة في سجل الرقابة
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_module ON public.audit_logs(module);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action_type);

-- 3. تفعيل الحماية وسياسات الوصول RLS
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- سياسات الوصول لجدول admin_users
DROP POLICY IF EXISTS "Allow all for admin_users" ON public.admin_users;
CREATE POLICY "Allow all for admin_users" ON public.admin_users
    FOR ALL USING (true) WITH CHECK (true);

-- سياسات الوصول لجدول audit_logs
DROP POLICY IF EXISTS "Allow all for audit_logs" ON public.audit_logs;
CREATE POLICY "Allow all for audit_logs" ON public.audit_logs
    FOR ALL USING (true) WITH CHECK (true);

-- 4. إدراج حساب المدير العام الافتراضي (Super Admin)
INSERT INTO public.admin_users (username, password, full_name, role, is_active, permissions)
VALUES (
    'admin',
    'admin123',
    'مدير النظام العام',
    'super_admin',
    true,
    '{}'::jsonb
)
ON CONFLICT (username) DO NOTHING;
