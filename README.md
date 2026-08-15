# إنجازي — Injazi

منصة ذكية للمعلم تبني ملف الإنجاز تلقائيًا من أعماله ومصادره التعليمية.

## الوضع الحالي

هذا المستودع يجمع:
- `injazi-backend/` — Backend أولي بـ Node.js + TypeScript + Prisma + PostgreSQL.
- `injazi-flutter/` — واجهة Flutter أولية لـ iOS وAndroid.

## مبدأ المنتج

> المعلم يعمل، وإنجازي يوثق الإنجاز.

النظام يبحث أولًا في المصادر المرتبطة، ثم يستخرج ويصنف الأدلة ويطابقها مع معايير الأداء. المعلم لا يكتب وصف كل شاهد ولا يصنفه يدويًا إلا عند الحاجة.

## التشغيل المحلي

### Backend

المتطلبات:
- Node.js LTS
- Docker Desktop

الأوامر:

```bash
cd injazi-backend
cp .env.example .env
docker compose up -d
npm install
npx prisma generate
npx prisma db push
npm run dev
```

اختبار:
```text
GET http://localhost:3000/health
```

### Flutter

المتطلبات:
- Flutter SDK
- Android Studio أو Xcode حسب المنصة

```bash
cd injazi-flutter
flutter pub get
flutter run
```

عنوان الـAPI الافتراضي في التطبيق هو `http://10.0.2.2:3000` للمحاكي على Android. عدله عند الحاجة في `lib/services/api_service.dart`.

## لا يوجد رفع خارجي مطلوب الآن

التطوير الحالي محلي بالكامل. لا تحتاج إنشاء حساب خدمة سحابية أو دفع أي مبلغ.

عندما نصل إلى GitHub، يكفي إنشاء مستودع مجاني ورفع هذا المجلد. لا نحتاج استضافة التطبيق أو قاعدة البيانات على الإنترنت في هذه المرحلة.

## المراحل القادمة

1. تشغيل الـBackend محليًا.
2. تشغيل Flutter وربطه بالـAPI.
3. إضافة تسجيل الدخول الحقيقي بـGoogle والبريد.
4. بناء رفع الملفات وتحليلها.
5. ربط Google Drive.
6. تنفيذ Connector مدرستي واختباره.
7. محرك المطابقة والتغطية.
8. إنشاء ملف PDF والرابط العام.
9. بعدها فقط نقرر الاستضافة المجانية الأنسب.
