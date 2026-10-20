# الدليل الجاهز للنسخ واللصق لرفع التطبيق على متجر Google Play Console

جميع المتطلبات التقنية والبرمجية تم تنفيذها بالكامل داخل المشروع، وتم إعداد هذا الملف لنسخ البيانات ولصقها مباشرة في **Google Play Console**.

---

## 1. الملفات الجاهزة للرفع
1. **ملف الحزمة الرسمي للمتجر (`.aab`):**
   * تحمله من GitHub Actions باسم **`ALghad-GooglePlay-AAB`** (بداخله ملف `app-release.aab`).
   * ترفعه في قسم: **Release $\rightarrow$ Production $\rightarrow$ Create new release**.
2. **أيقونة التطبيق (`512 × 512`):**
   * المسار: [app_icon_512x512.png](file:///c:/Users/crazy/Downloads/ALghad/google_play_assets/app_icon_512x512.png)
3. **صورة الغلاف (`1024 × 500`):**
   * المسار: [feature_graphic_1024x500.png](file:///c:/Users/crazy/Downloads/ALghad/google_play_assets/feature_graphic_1024x500.png)
4. **ملف سياسة الخصوصية (`HTML`):**
   * المسار: [privacy_policy.html](file:///c:/Users/crazy/Downloads/ALghad/google_play_assets/privacy_policy.html)
   * الرابط الجاهز عبر GitHub Raw / Pages بعد تفعيل GitHub Pages في المستودع:
     `https://figmacrazy-droid.github.io/gicapp/google_play_assets/privacy_policy.html`
5. **نسخة احتياطية من مفتاح التوقيع الرقمي (احفظها في مكان آمن جداً):**
   * المسار: [upload-keystore-backup.jks](file:///c:/Users/crazy/Downloads/ALghad/google_play_assets/upload-keystore-backup.jks)
   * كلمة مرور المفتاح (`storePassword` / `keyPassword`): `AlghadGIC@2026`
   * الاسم المستعار (`keyAlias`): `upload`

---

## 2. بيانات الدخول التجريبية لموظف مراجعة قوقل (App Access)
*(تم إنشاء هذا الحساب وتفعيله فعلياً في قاعدة بيانات Supabase الحية)*

في قسم **App content $\rightarrow$ App access**:
* اختر: **All or some functionality in my app is restricted** $\rightarrow$ اضغط **Add instructions**:
  * **Instruction name:** `Student Portal Login`
  * **Username / Academic ID:** `999999`
  * **Password:** `Test@12345`
  * **Any other information:**
    `Enter Academic ID 999999 and Password Test@12345 on the student login screen to access all student features (Results, Seating, Finance, and Notifications).`

---

## 3. نصوص صفحة المتجر الجاهزة للنسخ (Main Store Listing)

* **اسم التطبيق (App name):**
  `كلية الغد الدولية - GIC`
* **الوصف القصير (Short description):**
  `البوابة الإلكترونية الرسمية لطلاب كلية الغد الدولية للعلوم الطبية والتقنية.`
* **الوصف الكامل (Full description):**
  ```text
  التطبيق الرسمي لطلاب كلية الغد الدولية للعلوم الطبية والتقنية (GIC).
  يتيح التطبيق للطلاب الوصول السريع والآمن إلى كافة الخدمات الأكاديمية والإدارية:
  - استعراض النتائج الدراسية التفصيلية لكل فصل دراسي.
  - معرفة أرقام الجلوس وتوزيع القاعات الامتحانية.
  - متابعة الكشف المالي والرسوم الدراسية والمدفوعات.
  - استلام الإشعارات والتنبيهات الأكاديمية الفورية من إدارة الكلية.
  - تقديم طلبات التسجيل الإلكتروني والطلبات الطلابية العامة ومتابعة حالتها.
  - الاطلاع على التخصصات، التقويم الجامعي، واللوائح الأكاديمية.
  ```

---

## 4. إجابات استبيان أمان البيانات (Data Safety)
في قسم **App content $\rightarrow$ Data safety**:
1. **Does your app collect or share any of the required user data types?** $\rightarrow$ **Yes**
2. **Is all of the user data collected by your app encrypted in transit?** $\rightarrow$ **Yes**
3. **Do you provide a way for users to request that their data is deleted?** $\rightarrow$ **Yes** (ضع رابط سياسة الخصوصية أو رقم واتساب الكلية `+967775101453`).
4. **Data types:**
   * **Personal info:** `Name`, `User IDs` (الرقم الأكاديمي), `Phone number` (للتسجيل الإلكتروني).
   * **Device or other IDs:** `Device or other IDs` (رمز إشعارات FCM).
   * لجميع هذه الأنواع اختر: **Collected** (نعم) / **Shared** (لا) / الغرض: **App functionality**.
