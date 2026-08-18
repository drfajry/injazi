import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/api_service.dart';

class AppSession extends ChangeNotifier {
  final ApiService api = ApiService(
    baseUrl: 'https://injazi-backend-svxy.onrender.com',
  );

  bool ready = false;
  bool authenticated = false;
  bool hasProfile = false;

  AppSession() {
    initialize();
  }

  Future<void> initialize() async {
    try {
      authenticated = await api.isAuthenticated();

      if (authenticated) {
        final profile = await api.getProfile();

        if (profile == null) {
          authenticated = await api.isAuthenticated();
          hasProfile = false;
        } else {
          hasProfile = true;
        }
      }
    } catch (_) {
      await api.logout();
      authenticated = false;
      hasProfile = false;
    }

    ready = true;
    notifyListeners();
  }

  Future<void> refreshAfterLogin() async {
    authenticated = await api.isAuthenticated();

    if (!authenticated) {
      hasProfile = false;
      notifyListeners();
      return;
    }

    final profile = await api.getProfile();

    authenticated = await api.isAuthenticated();
    hasProfile = profile != null;

    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final profile = await api.getProfile();

    authenticated = await api.isAuthenticated();
    hasProfile = profile != null;

    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    authenticated = false;
    hasProfile = false;
    notifyListeners();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final session = AppSession();

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final location = state.uri.path;

      if (!session.ready) {
        return location == '/loading' ? null : '/loading';
      }

      final publicRoutes = <String>{
        '/',
        '/login',
        '/register',
        '/forgot-password',
        '/reset-password',
      };

      if (!session.authenticated) {
        if (publicRoutes.contains(location)) {
          return null;
        }

        return '/';
      }

      if (!session.hasProfile) {
        if (location == '/profile/setup') {
          return null;
        }

        if (location == '/login' ||
            location == '/register') {
          return '/profile/setup';
        }

        if (location == '/') {
          return null;
        }

        return '/profile/setup';
      }

      if (location == '/login' ||
          location == '/register' ||
          location == '/profile/setup') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          return LandingScreen(
            onStart: () => context.go('/login'),
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return AuthScreen(
            initialIsLogin: true,
            onAuthenticated: () async {
              await session.refreshAfterLogin();

              if (!context.mounted) return;

              if (session.hasProfile) {
                context.go('/dashboard');
              } else {
                context.go('/profile/setup');
              }
            },
          );
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          return AuthScreen(
            initialIsLogin: false,
            onAuthenticated: () async {
              await session.refreshAfterLogin();

              if (!context.mounted) return;

              if (session.hasProfile) {
                context.go('/dashboard');
              } else {
                context.go('/profile/setup');
              }
            },
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile/setup',
        builder: (context, state) {
          return ProfileSetupScreen(
            onCompleted: () async {
              await session.refreshProfile();

              if (!context.mounted) return;

              context.go('/dashboard');
            },
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/sources',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/portfolio',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),
    ],
  );

  runApp(
    InjaziApp(
      router: router,
      session: session,
    ),
  );
}

class InjaziApp extends StatelessWidget {
  final GoRouter router;
  final AppSession session;

  const InjaziApp({
    super.key,
    required this.router,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      routerConfig: router,
    );
  }
}









