# إنجازي — Backend Starter

هذا مجلد البداية الفعلي للـBackend لمنصة «إنجازي».

## ما الموجود الآن

- Express + TypeScript
- Prisma + PostgreSQL
- نماذج المستخدم والمعلم والمدرسة والسنة الدراسية
- مصادر التكامل: مدرستي / Google Drive / يدوي
- Evidence Engine أولي
- حالات الدليل
- ربط الدليل بالمؤشرات many-to-many
- Coverage API
- Portfolio API أولي
- طبقة Connectors مستقلة لـMadrasati وGoogle

## تشغيل محلي

1. انسخ `.env.example` إلى `.env`.
2. شغّل PostgreSQL:

```bash
docker compose up -d
```

3. ثبّت الحزم:

```bash
npm install
```

4. ولّد Prisma:

```bash
npm run prisma:generate
```

5. أنشئ قاعدة البيانات:

```bash
npm run prisma:migrate -- --name init
```

6. شغّل الخادم:

```bash
npm run dev
```

فحص الصحة:
`GET http://localhost:4000/health`

## ملاحظات إنتاجية مهمة

- مسارات المصادقة الموجودة حاليًا هي scaffolding فقط وليست Auth إنتاجي.
- موصل مدرستي متعمد أن يكون فارغًا إلى أن نحدد مسار الوصول المعتمد ونطبّق الـadapter.
- Google OAuth يحتاج callback/token vault قبل الإنتاج.
- رفع الملفات يحتاج Object Storage وفحص نوع الملف والحجم ومكافحة الملفات الضارة.
- لا نمرر بيانات الطلاب إلى طبقة AI إلا عند الحاجة وبأقل قدر ممكن.
