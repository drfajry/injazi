import 'package:flutter/material.dart';
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
      title: 'إنجازي',
      theme: InjaziTheme.light(),
      home: const HomeScreen(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
    );
  }
}
