-- 1. إضافة جدول الشجرة الأكاديمية
CREATE TABLE IF NOT EXISTS public.academic_tree (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES public.academic_tree(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    node_type TEXT NOT NULL CHECK (node_type IN ('year', 'specialty', 'batch', 'semester', 'group_shift')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- السماح بالوصول (RLS)
ALTER TABLE public.academic_tree ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read/write for academic_tree" ON public.academic_tree FOR ALL USING (true) WITH CHECK (true);

-- 2. إضافة حقل "العام الدراسي" لجدول الطلاب لربطهم بالسنة الصحيحة
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS academic_year TEXT DEFAULT '2023/2024';
