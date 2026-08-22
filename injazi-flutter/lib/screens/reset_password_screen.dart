import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  late final ApiService api;

  bool loading = false;
  bool completed = false;

  @override
  void initState() {
    super.initState();

    api = ApiService(
      baseUrl: 'https://injazi-backend-svxy.onrender.com',
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    api.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (widget.token.isEmpty) {
      _message('رابط إعادة التعيين غير صالح');
      return;
    }

    if (password.length < 8) {
      _message('يجب أن تتكون كلمة المرور من 8 أحرف أو أرقام على الأقل');
      return;
    }

    if (password != confirm) {
      _message('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => loading = true);

    try {
      await api.resetPassword(
        token: widget.token,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        completed = true;
      });
    } catch (e) {
      if (!mounted) return;

      _message(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: completed
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 56,
                              color: Color(0xFF15803D),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'تم تغيير كلمة المرور',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'يمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => context.go('/login'),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Text(
                                  'العودة لتسجيل الدخول',
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.lock_reset_outlined,
                              size: 54,
                              color: Color(0xFF0F766E),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'إعادة تعيين كلمة المرور',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'أدخل كلمة المرور الجديدة ثم أكدها مرة أخرى.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'كلمة المرور الجديدة',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: confirmController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'تأكيد كلمة المرور',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),
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
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'تغيير كلمة المرور',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text(
                                'العودة لتسجيل الدخول',
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}