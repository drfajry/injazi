import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'screens/home_screen.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();
runApp(const InjaziApp());
}

class InjaziApp extends StatelessWidget {
const InjaziApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Injazi',
theme: InjaziTheme.light(),
locale: const Locale('ar', 'SA'),
supportedLocales: const [
Locale('ar', 'SA'),
Locale('en', 'US'),
],
localizationsDelegates: GlobalMaterialLocalizations.delegates,
home: const HomeScreen(),
);
}
}
