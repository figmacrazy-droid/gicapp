-- ==============================================================================
-- 🏛️ كلية الغد المشرق للعلوم الطبية والتطبيقية
-- 🗄️ سكربت إنشاء وقواعد بيانات Supabase الكامل المخصص للتطبيق ولوحة التحكم (EXE)
-- ==============================================================================

-- تفعيل ملحق توليد المعرفات الفريدة UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. جدول الطلاب (Students Table) - يستورد من ملف الإكسل ومخصص للدخول وتطابق البيانات
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.students (
    academic_id VARCHAR(10) PRIMARY KEY,
    full_name TEXT NOT NULL,
    password TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    specialty TEXT NOT NULL,
    batch TEXT NOT NULL,
    semester TEXT NOT NULL,
    group_name TEXT NOT NULL,
    study_shift TEXT NOT NULL CHECK (study_shift IN ('الفترة الصباحية', 'الفترة المسائية', 'صباحية', 'مسائية')),
    level TEXT NOT NULL DEFAULT 'المستوى الأول',
    is_blocked BOOLEAN DEFAULT FALSE,
    failed_attempts INT DEFAULT 0,
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 2. جدول التعليمات والخطوات الديناميكية (System Instructions & Steps)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.system_instructions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_key TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT,
    steps JSONB NOT NULL DEFAULT '[]'::jsonb,
    note TEXT,
    external_url TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 3. جدول الكادر الأكاديمي والتدريس (Academic Staff)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.academic_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    photo_url TEXT NOT NULL,
    experience_years TEXT NOT NULL,
    specialty TEXT NOT NULL,
    bio TEXT,
    display_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 4. جدول الجداول الدراسية وجداول الامتحانات (Schedules)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('study', 'midterm', 'final')),
    file_url TEXT NOT NULL,
    is_pdf BOOLEAN DEFAULT TRUE,
    academic_year TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 5. جدول أرقام الجلوس (Seating Numbers)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.seating_numbers (
    academic_id VARCHAR(10) PRIMARY KEY REFERENCES public.students(academic_id) ON DELETE CASCADE,
    term TEXT NOT NULL,
    hall TEXT NOT NULL,
    seating_number TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 6. جدول أوائل الطلاب (Top Students - يستورد من جدول إكسل)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.top_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rank INT NOT NULL,
    student_name TEXT NOT NULL,
    specialty TEXT NOT NULL,
    gpa NUMERIC(5,2) NOT NULL,
    batch TEXT NOT NULL,
    academic_year TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 7. جدول نتائج الامتحانات والدرجات (Student Results - مواد ديناميكية)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_results (
    academic_id VARCHAR(10) PRIMARY KEY REFERENCES public.students(academic_id) ON DELETE CASCADE,
    subjects JSONB NOT NULL DEFAULT '{}'::jsonb,
    total_marks NUMERIC(6,2) NOT NULL,
    gpa NUMERIC(5,2) NOT NULL,
    grade TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 8. جدول أحداث التقويم والكالندر (Calendar Events - تمييز بالذهبي)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_date DATE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    is_highlighted_gold BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 9. جدول روابط التواصل الاجتماعي (Social Media Links)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.social_media_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform_name TEXT NOT NULL,
    url TEXT NOT NULL,
    icon_name TEXT NOT NULL,
    display_order INT DEFAULT 0
);

-- ------------------------------------------------------------------------------
-- 10. جدول الإنجازات (Our Achievements - تمديد النصوص وفيديو يوتيوب)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    date_str TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT NOT NULL,
    youtube_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 11. جدول خريجي الغد (Alumni Batches - مجلة الدفعة وحفل يوتيوب)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.alumni_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    batch_name TEXT NOT NULL,
    graduates_count TEXT NOT NULL,
    banner_image_url TEXT NOT NULL,
    magazine_pdf_url TEXT,
    ceremony_youtube_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 12. جدول الإشعارات والخدمات المالية (Finance Notifications)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.finance_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    academic_id VARCHAR(10) REFERENCES public.students(academic_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    date_str TEXT NOT NULL,
    details TEXT NOT NULL,
    amount NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 13. جدول دليل الطالب الجامعي (University Student Guide)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.university_guides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    file_url TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 14. 🖼️ جدول البنّرات الإعلانية بالسلايدر (Ad Banners)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ad_banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    image_url TEXT NOT NULL,
    title TEXT,
    link_url TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 15. 🎓 جدول التخصصات الأكاديمية (Academic Specialties)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.specialties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL, -- e.g. 'بكالوريوس إدارة أعمال'
    degree_type TEXT NOT NULL DEFAULT 'بكالوريوس', -- 'بكالوريوس' أو 'دبلوم عالي'
    image_url TEXT NOT NULL,
    visits_count INT DEFAULT 0,
    location TEXT DEFAULT 'صنعاء - دارس',
    display_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 16. 🔔 جدول الإشعارات العامة والخاصة (Push & In-App Notifications)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    academic_id VARCHAR(10) REFERENCES public.students(academic_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    notification_type TEXT NOT NULL DEFAULT 'general',
    route_name TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 17. 📱 جدول رموز الأجهزة للإشعارات الفورية Push (Device Tokens)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    academic_id VARCHAR(10) REFERENCES public.students(academic_id) ON DELETE CASCADE,
    device_token TEXT NOT NULL UNIQUE,
    platform TEXT DEFAULT 'android',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- ⚡ التريجرات التلقائية (Database Triggers)
-- ==============================================================================

CREATE OR REPLACE FUNCTION notify_new_schedule()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (academic_id, title, body, notification_type, route_name)
    VALUES (
        NULL, 
        'تم تنزيل جدول دراسي/امتحاني جديد! 📅', 
        'تم رفع: ' || NEW.title || ' - يمكنك المعاينة والتنزيل الآن.',
        'schedule',
        'schedules'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_schedule ON public.schedules;
CREATE TRIGGER trigger_notify_schedule
AFTER INSERT ON public.schedules
FOR EACH ROW EXECUTE FUNCTION notify_new_schedule();

CREATE OR REPLACE FUNCTION notify_new_result()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (academic_id, title, body, notification_type, route_name)
    VALUES (
        NEW.academic_id, 
        'تم إعلان النتيجة الدراسية الخاصة بك! 🎓', 
        'تم رفع درجات الامتحانات والتقدير العام. افحص النتيجة الآن.',
        'result',
        'results'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_result ON public.student_results;
CREATE TRIGGER trigger_notify_result
AFTER INSERT OR UPDATE ON public.student_results
FOR EACH ROW EXECUTE FUNCTION notify_new_result();

CREATE OR REPLACE FUNCTION notify_new_event()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (academic_id, title, body, notification_type, route_name)
    VALUES (
        NULL, 
        'حدث جديد في التقويم الأكاديمي! ⭐️', 
        NEW.title || ' - ' || NEW.description,
        'event',
        'calendar'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_event ON public.calendar_events;
CREATE TRIGGER trigger_notify_event
AFTER INSERT ON public.calendar_events
FOR EACH ROW EXECUTE FUNCTION notify_new_event();

-- ==============================================================================
-- 📥 بيانات تجريبية (Initial Seed Data)
-- ==============================================================================

-- إدراج البنّرات الإعلانية التجريبية
INSERT INTO public.ad_banners (image_url, title, display_order)
VALUES 
('assets/images/1.jpg', 'إعلان بدء التنسيق والقبول للعام الجديد', 1),
('assets/images/2.jpg', 'افتتاح قسم الصيدلة السريرية المتطور', 2),
('assets/images/3.jpg', 'تجهيز معمل التشخيص الميكروبيولوجي', 3)
ON CONFLICT DO NOTHING;

-- إدراج التخصصات الأكاديمية
INSERT INTO public.specialties (title, degree_type, image_url, visits_count, display_order)
VALUES 
('بكالوريوس إدارة أعمال', 'بكالوريوس', 'assets/images/specialty_1.png', 6635, 1),
('بكالوريوس إدارة صحية', 'بكالوريوس', 'assets/images/specialty_2.png', 5420, 2),
('تخصص المختبرات الطبية', 'بكالوريوس', 'assets/images/specialty_11.png', 3210, 3),
('تخصص الصيدلة', 'بكالوريوس', 'assets/images/specialty_12.png', 2980, 4)
ON CONFLICT DO NOTHING;

-- تفعيل سياسات الأمان العام RLS
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.specialties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read for auth" ON public.students FOR SELECT USING (true);
CREATE POLICY "Public read for instructions" ON public.system_instructions FOR SELECT USING (true);
CREATE POLICY "Public read for staff" ON public.academic_staff FOR SELECT USING (true);
CREATE POLICY "Public read for schedules" ON public.schedules FOR SELECT USING (true);
CREATE POLICY "Public read for seating" ON public.seating_numbers FOR SELECT USING (true);
CREATE POLICY "Public read for top_students" ON public.top_students FOR SELECT USING (true);
CREATE POLICY "Public read for results" ON public.student_results FOR SELECT USING (true);
CREATE POLICY "Public read for events" ON public.calendar_events FOR SELECT USING (true);
CREATE POLICY "Public read for social" ON public.social_media_links FOR SELECT USING (true);
CREATE POLICY "Public read for achievements" ON public.achievements FOR SELECT USING (true);
CREATE POLICY "Public read for alumni" ON public.alumni_batches FOR SELECT USING (true);
CREATE POLICY "Public read for finance" ON public.finance_notifications FOR SELECT USING (true);
CREATE POLICY "Public read for guides" ON public.university_guides FOR SELECT USING (true);
CREATE POLICY "Public read for banners" ON public.ad_banners FOR SELECT USING (true);
CREATE POLICY "Public read for specialties" ON public.specialties FOR SELECT USING (true);
CREATE POLICY "Public read for notifications" ON public.notifications FOR SELECT USING (true);
CREATE POLICY "Public write for tokens" ON public.device_tokens FOR INSERT WITH CHECK (true);
