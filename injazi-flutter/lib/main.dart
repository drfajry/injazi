import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();
runApp(const InjaziApp());
}

class InjaziApp extends StatefulWidget {
const InjaziApp({super.key});

@override
State<InjaziApp> createState() => _InjaziAppState();
}

class _InjaziAppState extends State<InjaziApp> {
late final ApiService api;
bool loading = true;
bool authenticated = false;

@override
void initState() {
super.initState();


api = ApiService(
  baseUrl: 'http://localhost:4000',
);

_checkSession();


}

Future<void> _checkSession() async {
final value = await api.isAuthenticated();


if (!mounted) return;

setState(() {
  authenticated = value;
  loading = false;
});


}

void _onAuthenticated() {
setState(() {
authenticated = true;
});
}

@override
void dispose() {
api.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'ط¥ظ†ط¬ط§ط²ظٹ',
theme: InjaziTheme.light(),
locale: const Locale('ar', 'SA'),
supportedLocales: const [
Locale('ar', 'SA'),
Locale('en', 'US'),
],
localizationsDelegates:
GlobalMaterialLocalizations.delegates,
home: loading
? const _LoadingScreen()
: authenticated
? const HomeScreen()
: AuthScreen(
onAuthenticated: _onAuthenticated,
),
);
}
}

class _LoadingScreen extends StatelessWidget {
const _LoadingScreen();

@override
Widget build(BuildContext context) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}
}

