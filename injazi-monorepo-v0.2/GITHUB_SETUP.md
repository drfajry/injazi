# رفع إنجازي إلى GitHub

## المطلوب
لا تحتاج أي خدمة مدفوعة.

### 1) إنشاء مستودع
من GitHub:
- New repository
- الاسم المقترح: `injazi`
- اختر Private في مرحلة التطوير.

### 2) افتح Terminal داخل مجلد المشروع

```bash
git init
git add .
git commit -m "Initial Injazi platform"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/injazi.git
git push -u origin main
```

### 3) مهم
لا ترفع:
- `.env`
- مفاتيح Google
- كلمات مرور
- رموز OAuth
- أي ملفات بيانات خاصة بالمعلمين.

ملفات `.gitignore` موجودة مسبقًا.

### 4) لا يوجد Deploy الآن
في هذه المرحلة GitHub فقط لحفظ الكود وإدارة الإصدارات.

**لا تنشئ Render أو Supabase أو Firebase الآن.**
سنقرر الاستضافة لاحقًا بعد تشغيل النسخة المحلية والتأكد من الـMVP.
