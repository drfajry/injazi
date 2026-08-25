import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../core/api_config.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final bool initialIsLogin;

  const AuthScreen({
    super.key,
    required this.onAuthenticated,
    this.initialIsLogin = true,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final ApiService api;

  bool isLogin = true;
  bool loading = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    isLogin = widget.initialIsLogin;

    api = ApiService(
      baseUrl: kApiBaseUrl,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    api.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        '\u0623\u062f\u062e\u0644 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u0648\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (isLogin) {
        await api.login(
          email: email,
          password: password,
        );

        if (!mounted) return;

        widget.onAuthenticated();
      } else {
        final result = await api.register(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (result['requiresEmailVerification'] == true) {
          context.go(
            '/verify-email',
            extra: email,
          );
        } else {
          widget.onAuthenticated();
        }
      }
    } catch (error) {
      if (!mounted) return;

      final message = error
          .toString()
          .replaceFirst('Exception: ', '');

      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 460,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FFFB),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 36,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '\u0625\u0646\u062c\u0627\u0632\u064a',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\u0645\u0644\u0641 \u0625\u0646\u062c\u0627\u0632\u0643 \u064a\u064f\u0628\u0646\u0649 \u062a\u0644\u0642\u0627\u0626\u064a\u064b\u0627',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text(
                            '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',
                          ),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text(
                            '\u062d\u0633\u0627\u0628 \u062c\u062f\u064a\u062f',
                          ),
                        ),
                      ],
                      selected: <bool>{isLogin},
                      onSelectionChanged: loading
                          ? null
                          : (value) {
                              setState(() {
                                isLogin = value.first;
                              });
                            },
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText:
                            '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: obscurePassword,
                      onSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                        labelText:
                            '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading ? null : () => context.go('/forgot-password'),
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: loading ? null : submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isLogin
                                    ? '\u062f\u062e\u0648\u0644'
                                    : '\u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u062d\u0633\u0627\u0628',
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () {
                              _showMessage(
                                '\u062a\u0633\u062c\u064a\u0644 Google \u0633\u064a\u062a\u0645 \u062a\u0641\u0639\u064a\u0644\u0647 \u0641\u064a \u0627\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u062a\u0627\u0644\u064a\u0629',
                              );
                            },
                      icon: const Icon(
                        Icons.account_circle_outlined,
                      ),
                      label: const Text(
                        '\u0645\u062a\u0627\u0628\u0639\u0629 \u0628\u0627\u0633\u062a\u062e\u062f\u0627\u0645 Google',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '\u0644\u0627 \u0646\u0633\u062a\u062e\u062f\u0645 \u0631\u0633\u0627\u0626\u0644 SMS\u060c \u0648\u0644\u0627 \u062a\u062d\u062a\u0627\u062c \u0625\u0644\u0649 \u0631\u0642\u0645 \u062c\u0648\u0627\u0644.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}






