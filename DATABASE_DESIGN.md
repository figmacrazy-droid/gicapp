# تصميم قاعدة بيانات Supabase ولوحة تحكم المدير
## تطبيق كلية الغد الدولية

---

## 📋 جدول المحتويات

1. [نظرة عامة](#نظرة-عامة)
2. [إعداد Supabase](#إعداد-supabase)
3. [تصميم قاعدة البيانات](#تصميم-قاعدة-البيانات)
4. [الجداول والعلاقات](#الجداول-والعلاقات)
5. [لوحة تحكم المدير](#لوحة-تحكم-المدير)
6. [خطوات التنفيذ](#خطوات-التنفيذ)
7. [الأمان والصلاحيات](#الأمان-والصلاحيات)

---

## 📌 نظرة عامة

هذا المستند يوثق تصميم قاعدة بيانات Supabase لتطبيق كلية الغد الدولية، بما في ذلك:
- إدارة المستخدمين والطلاب
- إدارة الأحداث والتقويم
- إدارة الإعلانات والأخبار
- لوحة تحكم المدير لإدارة المحتوى

---

## 🚀 إعداد Supabase

### الخطوة 1: إنشاء مشروع Supabase

1. اذهب إلى [supabase.com](https://supabase.com)
2. سجل حساب جديد أو سجل الدخول
3. أنشئ مشروع جديد باسم: `alghad-college`
4. اختر المنطقة الأقرب لليمن (مثلاً: `ap-southeast-1`)

### الخطوة 2: الحصول على بيانات الاتصال

بعد إنشاء المشروع، ستحتاج إلى:
- **Project URL**: من Settings > API
- **Anon Key**: من Settings > API
- **Service Role Key**: من Settings > API (للوحة التحكم فقط)

---

## 🗄️ تصميم قاعدة البيانات

### مخطط ERD (Entity Relationship Diagram)

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   users     │         │  students   │         │   events    │
├─────────────┤         ├─────────────┤         ├─────────────┤
│ id (PK)     │◄────────│ user_id (FK)│         │ id (PK)     │
│ email       │         │ student_id │         │ title       │
│ password    │         │ full_name  │         │ description │
│ role        │         │ level      │         │ date        │
│ created_at  │         │ phone      │         │ created_by  │
└─────────────┘         └─────────────┘         └─────────────┘
       │                       │                       │
       │                       │                       │
       ▼                       ▼                       ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   admins    │         │ attendance │         │  favorites  │
├─────────────┤         ├─────────────┤         ├─────────────┤
│ id (PK)     │         │ id (PK)    │         │ id (PK)     │
│ user_id (FK)│         │ student_id │         │ user_id (FK)│
│ permissions │         │ date       │         │ event_id(FK)│
└─────────────┘         │ status     │         └─────────────┘
                        └─────────────┘
```

---

## 📊 الجداول والعلاقات

### 1. جدول المستخدمين (users)

يخزن بيانات جميع مستخدمي التطبيق (طلاب، مدراء، إلخ)

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(50) DEFAULT 'student', -- 'student', 'admin', 'super_admin'
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء Index للبحث السريع
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

### 2. جدول الطلاب (students)

يخزن بيانات إضافية خاصة بالطلاب

```sql
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  student_id VARCHAR(50) UNIQUE NOT NULL, -- رقم الطالب الجامعي
  level VARCHAR(50), -- المستوى الدراسي
  department VARCHAR(100), -- القسم
  gpa DECIMAL(3, 2),
  enrollment_date DATE,
  address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_students_user_id ON students(user_id);
CREATE INDEX idx_students_student_id ON students(student_id);
```

### 3. جدول المدراء (admins)

يخزن بيانات المدراء وصلاحياتهم

```sql
CREATE TABLE admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  permissions JSONB DEFAULT '{}', -- صلاحيات المدير
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- مثال على permissions:
-- {
--   "manage_users": true,
--   "manage_events": true,
--   "manage_news": true,
--   "view_analytics": true
-- }

CREATE INDEX idx_admins_user_id ON admins(user_id);
```

### 4. جدول الأحداث (events)

يخزن الأحداث والإجازات في التقويم

```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  subtitle VARCHAR(255),
  description TEXT,
  event_date DATE NOT NULL,
  event_type VARCHAR(50) DEFAULT 'general', -- 'holiday', 'exam', 'ceremony', 'general'
  is_holiday BOOLEAN DEFAULT false,
  views INTEGER DEFAULT 0,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_events_type ON events(event_type);
```

### 5. جدول المفضلة (favorites)

يخزن الأحداث التي فضلها المستخدمون

```sql
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_event_id ON favorites(event_id);
```

### 6. جدول الحضور (attendance)

يخزن سجلات حضور الطلاب

```sql
CREATE TABLE attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status VARCHAR(20) DEFAULT 'present', -- 'present', 'absent', 'late'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(student_id, date)
);

CREATE INDEX idx_attendance_student_id ON attendance(student_id);
CREATE INDEX idx_attendance_date ON attendance(date);
```

### 7. جدول الأخبار (news)

يخزن أخبار وإعلانات الكلية

```sql
CREATE TABLE news (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  is_published BOOLEAN DEFAULT false,
  published_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_news_published ON news(is_published);
CREATE INDEX idx_news_date ON news(published_at);
```

### 8. جدول الإشعارات (notifications)

يخزن الإشعارات للمستخدمين

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'info', -- 'info', 'warning', 'success', 'error'
  is_read BOOLEAN DEFAULT false,
  data JSONB, -- بيانات إضافية
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
```

---

## 🔐 الأمان والصلاحيات

### Row Level Security (RLS)

تفعيل RLS على جميع الجداول:

```sql
-- تفعيل RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE news ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

### سياسات الأمان

#### 1. سياسات جدول المستخدمين

```sql
-- السماح للمستخدمين بقراءة بياناتهم فقط
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
USING (auth.uid() = id);

-- السماح للمدراء بقراءة جميع المستخدمين
CREATE POLICY "Admins can view all users"
ON users FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);

-- السماح للمستخدمين بتحديث بياناتهم فقط
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = id);
```

#### 2. سياسات جدول الأحداث

```sql
-- السماح للجميع بقراءة الأحداث
CREATE POLICY "Anyone can view events"
ON events FOR SELECT
USING (true);

-- السماح للمدراء بإضافة وتعديل الأحداث
CREATE POLICY "Admins can manage events"
ON events FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 4. سياسات جدول الخدمات

```sql
-- السماح للجميع بقراءة الفئات والخدمات النشطة
CREATE POLICY "Anyone can view active service categories"
ON service_categories FOR SELECT
USING (is_active = true);

CREATE POLICY "Anyone can view active services"
ON services FOR SELECT
USING (is_active = true);

-- السماح للمدراء بإدارة الفئات والخدمات
CREATE POLICY "Admins can manage service categories"
ON service_categories FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Admins can manage services"
ON services FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);

-- السماح للمستخدمين بقراءة طلباتهم فقط
CREATE POLICY "Users can view own service requests"
ON service_requests FOR SELECT
USING (auth.uid() = user_id);

-- السماح للمدراء بقراءة جميع الطلبات
CREATE POLICY "Admins can view all service requests"
ON service_requests FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);

-- السماح للمستخدمين بإنشاء طلبات
CREATE POLICY "Users can create service requests"
ON service_requests FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- السماح للمدراء بتحديث الطلبات
CREATE POLICY "Admins can update service requests"
ON service_requests FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 5. سياسات جدول الجداول الدراسية

```sql
-- السماح للطلاب بقراءة جداولهم فقط
CREATE POLICY "Students can view own study schedules"
ON study_schedules FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM students WHERE id = student_id
  )
);

-- السماح للمدراء بإدارة الجداول
CREATE POLICY "Admins can manage study schedules"
ON study_schedules FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 6. سياسات جدول الامتحانات

```sql
-- السماح للطلاب بقراءة جداول امتحاناتهم فقط
CREATE POLICY "Students can view own exam schedules"
ON exam_schedules FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM students WHERE id = student_id
  )
);

-- السماح للمدراء بإدارة جداول الامتحانات
CREATE POLICY "Admins can manage exam schedules"
ON exam_schedules FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 7. سياسات جدول النتائج

```sql
-- السماح للطلاب بقراءة نتائجهم المنشورة فقط
CREATE POLICY "Students can view own published results"
ON exam_results FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM students WHERE id = student_id
  ) AND is_published = true
);

-- السماح للمدراء بإدارة النتائج
CREATE POLICY "Admins can manage exam results"
ON exam_results FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 8. سياسات جدول الحسابات المالية

```sql
-- السماح للطلاب بقراءة حساباتهم فقط
CREATE POLICY "Students can view own financial accounts"
ON financial_accounts FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM students WHERE id = student_id
  )
);

-- السماح للمدراء بإدارة الحسابات
CREATE POLICY "Admins can manage financial accounts"
ON financial_accounts FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 9. سياسات جدول المعاملات المالية

```sql
-- السماح للطلاب بقراءة معاملاتهم فقط
CREATE POLICY "Students can view own financial transactions"
ON financial_transactions FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM students WHERE id = student_id
  )
);

-- السماح للمدراء بإدارة المعاملات
CREATE POLICY "Admins can manage financial transactions"
ON financial_transactions FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 10. سياسات جدول الأنشطة

```sql
-- السماح للجميع بقراءة الأنشطة النشطة
CREATE POLICY "Anyone can view active activities"
ON activities FOR SELECT
USING (is_active = true);

-- السماح للمدراء بإدارة الأنشطة
CREATE POLICY "Admins can manage activities"
ON activities FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 11. سياسات جدول الخريجين

```sql
-- السماح للجميع بقراءة الخريجين
CREATE POLICY "Anyone can view alumni"
ON alumni FOR SELECT
USING (true);

-- السماح للمدراء بإدارة الخريجين
CREATE POLICY "Admins can manage alumni"
ON alumni FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 12. سياسات جدول الإنجازات

```sql
-- السماح للجميع بقراءة الإنجازات
CREATE POLICY "Anyone can view achievements"
ON achievements FOR SELECT
USING (true);

-- السماح للمدراء بإدارة الإنجازات
CREATE POLICY "Admins can manage achievements"
ON achievements FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

#### 13. سياسات جدول الأخبار

```sql
-- السماح للجميع بقراءة الأخبار المنشورة
CREATE POLICY "Anyone can view published news"
ON news FOR SELECT
USING (is_published = true);

-- السماح للمدراء بقراءة جميع الأخبار
CREATE POLICY "Admins can view all news"
ON news FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);

-- السماح للمدراء بإدارة الأخبار
CREATE POLICY "Admins can manage news"
ON news FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admins
    WHERE user_id = auth.uid()
  )
);
```

---

## 📱 نظام الخدمات

### نظرة عامة على الخدمات

يحتوي التطبيق على 8 خدمات رئيسية في الواجهة الرئيسية، كل خدمة تحتوي على عدة خدمات فرعية:

1. **القبول والتسجيل**
2. **الأكاديمية**
3. **شؤون الطلاب**
4. **الكنترول**
5. **المالية**
6. **خريجي الغد**
7. **إنجازاتنا**
8. **تقديم طلب عام**

### مخطط ERD للخدمات

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ service_cat │         │  services  │         │service_reqs │
├─────────────┤         ├─────────────┤         ├─────────────┤
│ id (PK)     │◄────────│ category_id │         │ id (PK)     │
│ name        │         │ id (PK)    │◄────────│ service_id  │
│ icon_url    │         │ name       │         │ user_id (FK)│
│ order_index │         │ description│         │ status      │
│ is_active   │         │ route_name │         │ created_at  │
└─────────────┘         │ is_active  │         └─────────────┘
                        └─────────────┘
```

### جدول فئات الخدمات (service_categories)

يخزن الفئات الرئيسية للخدمات (القبول، الأكاديمية، شؤون الطلاب، إلخ)

```sql
CREATE TABLE service_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  name_ar VARCHAR(255) NOT NULL,
  icon_url TEXT,
  route_name VARCHAR(100),
  order_index INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إضافة الفئات الرئيسية
INSERT INTO service_categories (name, name_ar, icon_url, route_name, order_index) VALUES
('Admission', 'القبول والتسجيل', 'assets/new_icons/admission.png', 'admission', 1),
('Academy', 'الأكاديمية', 'assets/new_icons/academy.png', 'academy', 2),
('Student Affairs', 'شؤون الطلاب', 'assets/new_icons/student_affairs.png', 'student_affairs', 3),
('Control', 'الكنترول', 'assets/new_icons/control.png', 'control', 4),
('Finance', 'المالية', 'assets/new_icons/finance.png', 'finance', 5),
('Alumni', 'خريجي الغد', 'assets/new_icons/alumni.png', 'alumni', 6),
('Achievements', 'إنجازاتنا', 'assets/new_icons/achievements.png', 'achievements', 7),
('General Request', 'تقديم طلب عام', 'assets/new_icons/general_request.png', 'general_request', 8);

CREATE INDEX idx_service_categories_order ON service_categories(order_index);
```

### جدول الخدمات (services)

يخزن الخدمات الفرعية لكل فئة

```sql
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES service_categories(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  name_ar VARCHAR(255) NOT NULL,
  description TEXT,
  route_name VARCHAR(100),
  order_index INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إضافة خدمات القبول والتسجيل
INSERT INTO services (category_id, name, name_ar, description, route_name, order_index) VALUES
((SELECT id FROM service_categories WHERE name = 'Admission'), 'Admission Requirements', 'متطلبات القبول التسجيل في الكلية', 'متطلبات القبول والتسجيل في الكلية', 'admission_requirements', 1),
((SELECT id FROM service_categories WHERE name = 'Admission'), 'Online Registration', 'التسجيل اونلاين', 'التسجيل اونلاين', 'online_registration', 2),
((SELECT id FROM service_categories WHERE name = 'Admission'), 'Ministry Portal', 'بوابة التنسيق الالكتروني لوزارة التربية والتعليم والبحث العلمي', 'بوابة التنسيق الالكتروني لوزارة التربية والتعليم والبحث العلمي', 'ministry_portal', 3),
((SELECT id FROM service_categories WHERE name = 'Admission'), 'Withdrawal System', 'نظام الإنسحاب', 'نظام الإنسحاب', 'withdrawal_system', 4);

-- إضافة خدمات الأكاديمية
INSERT INTO services (category_id, name, name_ar, description, route_name, order_index) VALUES
((SELECT id FROM service_categories WHERE name = 'Academy'), 'Academic Staff', 'الكادر الأكاديمي والتدريسي', 'الكادر الأكاديمي والتدريسي', 'academic_staff', 1),
((SELECT id FROM service_categories WHERE name = 'Academy'), 'Field Training', 'التدريب الميداني', 'التدريب الميداني', 'field_training', 2);

-- إضافة خدمات شؤون الطلاب
INSERT INTO services (category_id, name, name_ar, description, route_name, order_index) VALUES
((SELECT id FROM service_categories WHERE name = 'Student Affairs'), 'Study Schedules', 'الجداول الدراسية', 'الجداول الدراسية', 'study_schedules', 1),
((SELECT id FROM service_categories WHERE name = 'Student Affairs'), 'Activities', 'الأنشطة والفعاليات', 'الأنشطة والفعاليات', 'activities', 2),
((SELECT id FROM service_categories WHERE name = 'Student Affairs'), 'Freeze Request', 'تقديم طلب وقف قيد', 'تقديم طلب وقف قيد', 'freeze_request', 3),
((SELECT id FROM service_categories WHERE name = 'Student Affairs'), 'Unfreeze Request', 'تقديم طلب فتح قيد', 'تقديم طلب فتح قيد', 'unfreeze_request', 4),
((SELECT id FROM service_categories WHERE name = 'Student Affairs'), 'Transfer Request', 'تقديم طلب مقاصصة', 'تقديم طلب مقاصصة', 'transfer_request', 5),
((SELECT id FROM service_categories WHERE name = 'Student Affairs'), 'Withdraw File Request', 'تقديم طلب سحب ملف', 'تقديم طلب سحب ملف', 'withdraw_file_request', 6);

-- إضافة خدمات الكنترول
INSERT INTO services (category_id, name, name_ar, description, route_name, order_index) VALUES
((SELECT id FROM service_categories WHERE name = 'Control'), 'Midterm Exams', 'جداول الإمتحانات النصفية', 'جداول الإمتحانات النصفية', 'midterm_exams', 1),
((SELECT id FROM service_categories WHERE name = 'Control'), 'Final Exams', 'جداول الإمتحانات النهائية', 'جداول الإمتحانات النهائية', 'final_exams', 2),
((SELECT id FROM service_categories WHERE name = 'Control'), 'Seat Numbers', 'أرقام الجلوس', 'أرقام الجلوس', 'seat_numbers', 3),
((SELECT id FROM service_categories WHERE name = 'Control'), 'Exam Committees', 'اللجان الامتحانية', 'اللجان الامتحانية', 'exam_committees', 4),
((SELECT id FROM service_categories WHERE name = 'Control'), 'Top Students', 'أوائل الطلاب', 'أوائل الطلاب', 'top_students', 5),
((SELECT id FROM service_categories WHERE name = 'Control'), 'Results', 'النتائج', 'النتائج', 'results', 6),
((SELECT id FROM service_categories WHERE name = 'Control'), 'Appeal Request', 'تقديم طلب تظلم', 'تقديم طلب تظلم', 'appeal_request', 7);

-- إضافة خدمات المالية
INSERT INTO services (category_id, name, name_ar, description, route_name, order_index) VALUES
((SELECT id FROM service_categories WHERE name = 'Finance'), 'Account Statement', 'طلب كشف حساب تفصيلي', 'طلب كشف حساب تفصيلي', 'account_statement', 1),
((SELECT id FROM service_categories WHERE name = 'Finance'), 'Payment Receipt', 'سند تسديد الرسوم الدراسية', 'سند تسديد الرسوم الدراسية', 'payment_receipt', 2),
((SELECT id FROM service_categories WHERE name = 'Finance'), 'Pay Fees', 'تسديد رسوم', 'تسديد رسوم', 'pay_fees', 3),
((SELECT id FROM service_categories WHERE name = 'Finance'), 'Transfer Fees', 'تحويل رسوم', 'تحويل رسوم', 'transfer_fees', 4),
((SELECT id FROM service_categories WHERE name = 'Finance'), 'Refund Fees', 'سحب رسوم', 'سحب رسوم', 'refund_fees', 5);

CREATE INDEX idx_services_category ON services(category_id);
CREATE INDEX idx_services_order ON services(order_index);
```

### جدول طلبات الخدمات (service_requests)

يخزن الطلبات المقدمة من الطلاب للخدمات المختلفة

```sql
CREATE TABLE service_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  service_id UUID REFERENCES services(id) ON DELETE CASCADE,
  category_id UUID REFERENCES service_categories(id) ON DELETE CASCADE,
  request_type VARCHAR(100), -- نوع الطلب (freeze, unfreeze, transfer, etc.)
  subject VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'in_review'
  priority VARCHAR(20) DEFAULT 'normal', -- 'low', 'normal', 'high', 'urgent'
  attachment_url TEXT,
  attachment_type VARCHAR(50), -- 'image', 'pdf', 'document'
  admin_notes TEXT,
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_service_requests_user ON service_requests(user_id);
CREATE INDEX idx_service_requests_service ON service_requests(service_id);
CREATE INDEX idx_service_requests_status ON service_requests(status);
CREATE INDEX idx_service_requests_date ON service_requests(created_at);
```

### جدول الجداول الدراسية (study_schedules)

يخزن جداول الدروس للطلاب

```sql
CREATE TABLE study_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  semester VARCHAR(50) NOT NULL, -- الفصل الدراسي
  academic_year VARCHAR(20) NOT NULL, -- السنة الأكاديمية
  course_code VARCHAR(20) NOT NULL,
  course_name VARCHAR(255) NOT NULL,
  instructor_name VARCHAR(255),
  day_of_week VARCHAR(20) NOT NULL, -- 'Sunday', 'Monday', etc.
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room_number VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_study_schedules_student ON study_schedules(student_id);
CREATE INDEX idx_study_schedules_semester ON study_schedules(semester);
```

### جدول جداول الامتحانات (exam_schedules)

يخزن جداول الامتحانات النصفية والنهائية

```sql
CREATE TABLE exam_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  exam_type VARCHAR(50) NOT NULL, -- 'midterm', 'final'
  semester VARCHAR(50) NOT NULL,
  academic_year VARCHAR(20) NOT NULL,
  course_code VARCHAR(20) NOT NULL,
  course_name VARCHAR(255) NOT NULL,
  exam_date DATE NOT NULL,
  exam_time TIME NOT NULL,
  room_number VARCHAR(20),
  seat_number VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_exam_schedules_student ON exam_schedules(student_id);
CREATE INDEX idx_exam_schedules_date ON exam_schedules(exam_date);
CREATE INDEX idx_exam_schedules_type ON exam_schedules(exam_type);
```

### جدول النتائج (exam_results)

يخزن نتائج الامتحانات للطلاب

```sql
CREATE TABLE exam_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  exam_schedule_id UUID REFERENCES exam_schedules(id) ON DELETE CASCADE,
  course_code VARCHAR(20) NOT NULL,
  course_name VARCHAR(255) NOT NULL,
  grade DECIMAL(5, 2),
  grade_letter VARCHAR(2), -- 'A', 'B', 'C', 'D', 'F'
  points DECIMAL(3, 2),
  semester VARCHAR(50) NOT NULL,
  academic_year VARCHAR(20) NOT NULL,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_exam_results_student ON exam_results(student_id);
CREATE INDEX idx_exam_results_course ON exam_results(course_code);
```

### جدول الحسابات المالية (financial_accounts)

يخزن حسابات الطلاب المالية

```sql
CREATE TABLE financial_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  balance DECIMAL(10, 2) DEFAULT 0.00,
  total_paid DECIMAL(10, 2) DEFAULT 0.00,
  total_due DECIMAL(10, 2) DEFAULT 0.00,
  academic_year VARCHAR(20),
  semester VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_financial_accounts_student ON financial_accounts(student_id);
```

### جدول المعاملات المالية (financial_transactions)

يخزن سجل المعاملات المالية

```sql
CREATE TABLE financial_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  account_id UUID REFERENCES financial_accounts(id) ON DELETE CASCADE,
  transaction_type VARCHAR(50) NOT NULL, -- 'payment', 'refund', 'transfer', 'fee'
  amount DECIMAL(10, 2) NOT NULL,
  description TEXT,
  payment_method VARCHAR(50), -- 'cash', 'bank_transfer', 'online'
  receipt_number VARCHAR(100),
  receipt_url TEXT,
  transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_financial_transactions_student ON financial_transactions(student_id);
CREATE INDEX idx_financial_transactions_date ON financial_transactions(transaction_date);
CREATE INDEX idx_financial_transactions_type ON financial_transactions(transaction_type);
```

### جدول الكادر الأكاديمي (academic_staff)

يخزن بيانات أعضاء هيئة التدريس

```sql
CREATE TABLE academic_staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  name_ar VARCHAR(255) NOT NULL,
  title VARCHAR(100), -- 'Professor', 'Lecturer', etc.
  department VARCHAR(100),
  email VARCHAR(255),
  phone VARCHAR(20),
  specialization VARCHAR(255),
  bio TEXT,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_academic_staff_department ON academic_staff(department);
```

### جدول التدريب الميداني (field_training)

يخزن معلومات التدريب الميداني للطلاب

```sql
CREATE TABLE field_training (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  institution_name VARCHAR(255) NOT NULL,
  institution_address TEXT,
  supervisor_name VARCHAR(255),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  training_hours INTEGER,
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'ongoing', 'completed'
  evaluation_score DECIMAL(3, 2),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_field_training_student ON field_training(student_id);
CREATE INDEX idx_field_training_status ON field_training(status);
```

### جدول الأنشطة والفعاليات (activities)

يخزن الأنشطة والفعاليات الطلابية

```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  activity_type VARCHAR(50), -- 'sports', 'cultural', 'academic', 'social'
  activity_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  location VARCHAR(255),
  organizer VARCHAR(255),
  max_participants INTEGER,
  current_participants INTEGER DEFAULT 0,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_activities_date ON activities(activity_date);
CREATE INDEX idx_activities_type ON activities(activity_type);
```

### جدول مشاركة الطلاب في الأنشطة (activity_participants)

يخزن الطلاب المشاركين في الأنشطة

```sql
CREATE TABLE activity_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID REFERENCES activities(id) ON DELETE CASCADE,
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  attendance_status VARCHAR(20), -- 'registered', 'attended', 'absent'
  UNIQUE(activity_id, student_id)
);

CREATE INDEX idx_activity_participants_activity ON activity_participants(activity_id);
CREATE INDEX idx_activity_participants_student ON activity_participants(student_id);
```

### جدول الخريجين (alumni)

يخزن بيانات خريجي الكلية

```sql
CREATE TABLE alumni (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  graduation_year INTEGER,
  graduation_date DATE,
  degree VARCHAR(100),
  gpa DECIMAL(3, 2),
  current_job_title VARCHAR(255),
  current_company VARCHAR(255),
  work_location VARCHAR(255),
  linkedin_url TEXT,
  is_employed BOOLEAN DEFAULT false,
  success_story TEXT,
  image_url TEXT,
  is_featured BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_alumni_graduation_year ON alumni(graduation_year);
CREATE INDEX idx_alumni_featured ON alumni(is_featured);
```

### جدول الإنجازات (achievements)

يخزن إنجازات الكلية والطلاب

```sql
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  achievement_type VARCHAR(50), -- 'college', 'student', 'staff'
  achievement_date DATE,
  category VARCHAR(100), -- 'academic', 'sports', 'research', 'community'
  image_url TEXT,
  is_featured BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_achievements_type ON achievements(achievement_type);
CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_featured ON achievements(is_featured);
```

---

## 🎛️ لوحة تحكم المدير

### الميزات الرئيسية

#### 1. إدارة المستخدمين
- عرض قائمة جميع المستخدمين
- إضافة مستخدم جديد
- تعديل بيانات المستخدم
- حذف/تعطيل مستخدم
- تغيير دور المستخدم (طالب/مدير)
- تصدير بيانات المستخدمين (CSV/Excel)

#### 2. إدارة الطلاب
- عرض قائمة الطلاب
- إضافة طالب جديد
- تعديل بيانات الطالب
- عرض سجل الحضور
- عرض المعدل التراكمي (GPA)
- تصدير بيانات الطلاب

#### 3. إدارة الأحداث والتقويم
- عرض جميع الأحداث
- إضافة حدث جديد
- تعديل حدث موجود
- حذف حدث
- نشر إجازات رسمية
- تحديد نوع الحدث (إجازة، اختبار، حفل، إلخ)

#### 4. إدارة الأخبار
- عرض جميع الأخبار
- إضافة خبر جديد
- تعديل خبر
- حذف خبر
- نشر/إلغاء نشر خبر
- رفع صور للخبر

#### 5. إدارة الحضور
- عرض سجل الحضور
- تسجيل حضور يومي
- تعديل سجل الحضور
- عرض إحصائيات الحضور
- تصدير تقارير الحضور

#### 6. إدارة الخدمات
- عرض جميع فئات الخدمات
- إضافة/تعديل/حذف فئات الخدمات
- إدارة الخدمات الفرعية لكل فئة
- تفعيل/تعطيل الخدمات
- ترتيب الخدمات
- إدارة طلبات الخدمات
- مراجعة الطلبات المقدمة
- قبول/رفض الطلبات

#### 7. إدارة الجداول الدراسية
- عرض جداول الطلاب
- إضافة جداول جديدة
- تعديل الجداول
- حذف الجداول
- تصدير الجداول

#### 8. إدارة الامتحانات
- عرض جداول الامتحانات النصفية والنهائية
- إضافة جداول امتحانات
- تعديل جداول الامتحانات
- إدارة أرقام الجلوس
- إدارة اللجان الامتحانية
- نشر النتائج
- إدارة طلبات التظلم

#### 9. إدارة المالية
- عرض حسابات الطلاب
- إضافة معاملات مالية
- تعديل المعاملات
- إصدار سندات دفع
- إدارة التحويلات والاستردادات
- تصدير التقارير المالية

#### 10. إدارة الكادر الأكاديمي
- عرض جميع أعضاء هيئة التدريس
- إضافة عضو جديد
- تعديل بيانات العضو
- حذف عضو
- إدارة التخصصات

#### 11. إدارة الأنشطة
- عرض جميع الأنشطة
- إضافة نشاط جديد
- تعديل نشاط
- حذف نشاط
- إدارة المشاركين
- تتبع الحضور

#### 12. إدارة الخريجين
- عرض قائمة الخريجين
- إضافة خريج جديد
- تعديل بيانات الخريج
- تمييز قصص النجاح
- إدارة التوظيف

#### 13. إدارة الإنجازات
- عرض جميع الإنجازات
- إضافة إنجاز جديد
- تعديل إنجاز
- حذف إنجاز
- تمييز الإنجازات المميزة

#### 14. الإحصائيات والتقارير
- عدد المستخدمين النشطين
- عدد الطلاب المسجلين
- الأحداث القادمة
- نسبة الحضور
- الأخبار المنشورة
- عدد الطلبات المعلقة
- إحصائيات مالية
- رسوم بيانية تفاعلية

### تقنيات لوحة التحكم المقترحة

#### الخيار 1: Supabase Dashboard (مدمج)
- استخدام لوحة تحكم Supabase المدمجة
- إنشاء Views مخصصة
- استخدام SQL Editor للإدارة

#### الخيار 2: React Admin Panel
```bash
# تثبيت React Admin
npx create-react-app admin-panel
cd admin-panel
npm install react-admin ra-data-supabase
```

#### الخيار 3: Flutter Admin Panel
- إنشاء تطبيق Flutter منفصل للإدارة
- استخدام نفس تصميم التطبيق الرئيسي
- ربطه بـ Supabase

---

## 📝 خطوات التنفيذ

### الخطوة 1: إعداد Supabase

1. إنشاء مشروع Supabase جديد
2. الحصول على مفاتيح API
3. تفعيل Authentication
4. إعداد Email Templates

### الخطوة 2: إنشاء الجداول

1. افتح SQL Editor في Supabase
2. نفذ جميع أوامر SQL المذكورة أعلاه
3. تأكد من إنشاء جميع الجداول
4. تفعيل Row Level Security

### الخطوة 3: إضافة البيانات الأولية

```sql
-- إضافة مدير افتراضي
INSERT INTO users (email, password_hash, full_name, role) 
VALUES ('admin@alghad.edu', '$2b$10$...', 'مدير النظام', 'super_admin');

-- إضافة أحداث أولية
INSERT INTO events (title, subtitle, description, event_date, event_type, is_holiday)
VALUES 
  ('إجازة عيد الفطر', 'إجازة رسمية', 'إجازة عيد الفطر المبارك', '2026-03-30', 'holiday', true),
  ('بدء الفصل الدراسي الأول', 'السنة الأكاديمية 2026', 'بدء الدراسة للفصل الأول', '2026-09-01', 'general', false);
```

### الخطوة 4: ربط التطبيق بـ Supabase

#### إضافة مكتبة Supabase في Flutter

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
```

#### إعداد Supabase في main.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  runApp(MyApp());
}
```

### الخطوة 5: إنشاء لوحة التحكم

#### باستخدام React Admin

```tsx
// admin-panel/src/App.tsx
import { Admin, Resource, ListGuesser, EditGuesser } from 'react-admin';
import supabaseDataProvider from 'ra-data-supabase';

const dataProvider = supabaseDataProvider({
  apiUrl: 'YOUR_SUPABASE_URL',
  apiKey: 'YOUR_SERVICE_ROLE_KEY',
});

const App = () => (
  <Admin dataProvider={dataProvider}>
    <Resource name="users" list={ListGuesser} edit={EditGuesser} />
    <Resource name="students" list={ListGuesser} edit={EditGuesser} />
    <Resource name="events" list={ListGuesser} edit={EditGuesser} />
    <Resource name="news" list={ListGuesser} edit={EditGuesser} />
  </Admin>
);
```

---

## 🔌 API Endpoints

### Authentication

```dart
// تسجيل الدخول
await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password',
);

// تسجيل خروج
await supabase.auth.signOut();

// تسجيل مستخدم جديد
await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'password',
);
```

### CRUD Operations

```dart
// قراءة البيانات
final response = await supabase
  .from('events')
  .select()
  .eq('event_type', 'holiday');

// إضافة بيانات
await supabase.from('events').insert({
  'title': 'حدث جديد',
  'description': 'وصف الحدث',
  'event_date': '2026-12-01',
});

// تحديث بيانات
await supabase
  .from('events')
  .update({'title': 'عنوان محدث'})
  .eq('id', eventId);

// حذف بيانات
await supabase.from('events').delete().eq('id', eventId);
```

---

## 📊 Views مخصصة للإحصائيات

```sql
-- View: إحصائيات عامة
CREATE VIEW admin_stats AS
SELECT
  (SELECT COUNT(*) FROM users WHERE is_active = true) as active_users,
  (SELECT COUNT(*) FROM students) as total_students,
  (SELECT COUNT(*) FROM events WHERE event_date >= CURRENT_DATE) as upcoming_events,
  (SELECT COUNT(*) FROM news WHERE is_published = true) as published_news,
  (SELECT COUNT(*) FROM attendance WHERE date = CURRENT_DATE AND status = 'present') as today_attendance;

-- View: حضور الطلاب
CREATE VIEW student_attendance_view AS
SELECT
  s.student_id,
  s.full_name,
  s.level,
  COUNT(CASE WHEN a.status = 'present' THEN 1 END) as present_days,
  COUNT(CASE WHEN a.status = 'absent' THEN 1 END) as absent_days,
  ROUND(
    (COUNT(CASE WHEN a.status = 'present' THEN 1 END)::FLOAT / 
     COUNT(*)::FLOAT) * 100, 2
  ) as attendance_percentage
FROM students s
LEFT JOIN attendance a ON s.id = a.student_id
GROUP BY s.id, s.student_id, s.full_name, s.level;
```

---

## 🔄 Real-time Subscriptions

```dart
// الاستماع للتغييرات في الأحداث
supabase
  .channel('events_changes')
  .on('postgres_changes', event: 'INSERT', schema: 'public', table: 'events')
  .on('postgres_changes', event: 'UPDATE', schema: 'public', table: 'events')
  .on('postgres_changes', event: 'DELETE', schema: 'public', table: 'events')
  .subscribe();

// الاستماع للإشعارات
supabase
  .channel('notifications')
  .on('postgres_changes', event: 'INSERT', schema: 'public', table: 'notifications')
  .subscribe();
```

---

## 📱 Storage (تخزين الملفات)

### إعداد Storage Buckets

```sql
-- إنشاء bucket للصور
INSERT INTO storage.buckets (id, name, public)
VALUES ('images', 'images', true);

-- إنشاء bucket للمستندات
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);

-- سياسات الوصول
CREATE POLICY "Public images are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'images');
```

### رفع الملفات

```dart
// رفع صورة
final file = File('path/to/image.jpg');
final response = await supabase.storage
  .from('images')
  .upload('public/avatar_$userId.jpg', file);
```

---

## 🎨 تصميم واجهة لوحة التحكم

### الهيكل المقترح

```
لوحة التحكم
├── Dashboard (الرئيسية)
│   ├── الإحصائيات العامة
│   ├── الأحداث القادمة
│   └── آخر الأخبار
├── المستخدمين
│   ├── قائمة المستخدمين
│   ├── إضافة مستخدم
│   └── الصلاحيات
├── الطلاب
│   ├── قائمة الطلاب
│   ├── بيانات الطالب
│   └── سجل الحضور
├── الأحداث
│   ├── التقويم
│   ├── إضافة حدث
│   └── إدارة الإجازات
├── الأخبار
│   ├── قائمة الأخبار
│   ├── إضافة خبر
│   └── النشر
└── الإعدادات
    ├── إعدادات النظام
    ├── النسخ الاحتياطي
    └── السجلات
```

---

## 🚀 خطوات التطوير المستقبلية

1. **المرحلة 1**: إعداد قاعدة البيانات الأساسية
2. **المرحلة 2**: ربط التطبيق بـ Supabase
3. **المرحلة 3**: إنشاء لوحة التحكم
4. **المرحلة 4**: إضافة الميزات المتقدمة
5. **المرحلة 5**: الاختبار والنشر

---

## 📞 الدعم والمساعدة

للمزيد من المعلومات:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Guide](https://supabase.com/docs/guides/with/flutter)
- [React Admin Documentation](https://marmelab.com/react-admin/)

---

**آخر تحديث**: 30 سبتمبر 2026
