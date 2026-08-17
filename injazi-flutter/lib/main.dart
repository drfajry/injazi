import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/profile_setup_screen.dart';
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
  bool hasProfile = false;
  bool showAuth = false;

  @override
  void initState() {
    super.initState();

    api = ApiService(
      baseUrl: 'http://localhost:4000',
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final loggedIn = await api.isAuthenticated();

      if (!loggedIn) {
        if (!mounted) return;

        setState(() {
          authenticated = false;
          hasProfile = false;
          showAuth = false;
          loading = false;
        });

        return;
      }

      final profile = await api.getProfile();

      if (!mounted) return;

      setState(() {
        authenticated = true;
        hasProfile = profile != null;
        showAuth = false;
        loading = false;
      });
    } catch (_) {
      await api.logout();

      if (!mounted) return;

      setState(() {
        authenticated = false;
        hasProfile = false;
        showAuth = false;
        loading = false;
      });
    }
  }

  void _showLogin() {
    setState(() {
      showAuth = true;
    });
  }

  Future<void> _onAuthenticated() async {
    final profile = await api.getProfile();

    if (!mounted) return;

    setState(() {
      authenticated = true;
      hasProfile = profile != null;
      showAuth = false;
    });
  }

  void _onProfileCompleted() {
    setState(() {
      authenticated = true;
      hasProfile = true;
      showAuth = false;
    });
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  Widget _home() {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authenticated) {
      return showAuth
          ? AuthScreen(
              onAuthenticated: _onAuthenticated,
            )
          : LandingScreen(
              onStart: _showLogin,
            );
    }

    if (!hasProfile) {
      return ProfileSetupScreen(
        onCompleted: _onProfileCompleted,
      );
    }

    return const HomeScreen();
  }

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
      localizationsDelegates:
          GlobalMaterialLocalizations.delegates,
      home: _home(),
    );
  }
}
