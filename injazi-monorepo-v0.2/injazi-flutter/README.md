# إنجازي Flutter

واجهة أولية لـ iOS وAndroid.

## التشغيل

```bash
flutter pub get
flutter run
```

## الاتصال بالـBackend

لـ Android Emulator استخدم:
`http://10.0.2.2:3000`

لجهاز حقيقي على نفس الشبكة، استخدم IP جهاز الكمبيوتر بدل `10.0.2.2`.

عدّل:
`lib/services/api_service.dart`

قبل ربط التطبيق بالحسابات الحقيقية، سنضيف طبقة جلسة/Token حقيقية بدل تمرير `userId` من الواجهة.
