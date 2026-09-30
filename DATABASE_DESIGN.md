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

#### 3. سياسات جدول الأخبار

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

#### 6. الإحصائيات والتقارير
- عدد المستخدمين النشطين
- عدد الطلاب المسجلين
- الأحداث القادمة
- نسبة الحضور
- الأخبار المنشورة
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
