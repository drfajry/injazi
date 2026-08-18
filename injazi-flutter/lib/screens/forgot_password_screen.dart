import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  late final ApiService api;
  bool loading = false;
  bool sent = false;

  @override
  void initState() {
    super.initState();
    api = ApiService(baseUrl: 'https://injazi-backend-svxy.onrender.com');
  }

  @override
  void dispose() {
    emailController.dispose();
    api.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _message('ط£ط¯ط®ظ„ ط§ظ„ط¨ط±ظٹط¯ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ');
      return;
    }

    setState(() => loading = true);

    try {
      await api.forgotPassword(email: email);
      if (!mounted) return;
      setState(() => sent = true);
    } catch (e) {
      if (!mounted) return;
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_reset_outlined, size: 54, color: Color(0xFF0F766E)),
                    const SizedBox(height: 18),
                    Text(
                      sent ? 'طھظ… ط¥ط±ط³ط§ظ„ ط±ط§ط¨ط· ط¥ط¹ط§ط¯ط© ط§ظ„طھط¹ظٹظٹظ†' : 'ظ†ط³ظٹطھ ظƒظ„ظ…ط© ط§ظ„ظ…ط±ظˆط±طں',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sent
                          ? 'ط¥ط°ط§ ظƒط§ظ† ط§ظ„ط¨ط±ظٹط¯ ظ…ط³ط¬ظ„ظ‹ط§ ظ„ط¯ظٹظ†ط§ ظپط³طھطµظ„ظƒ ط±ط³ط§ظ„ط© ظ„ط¥ط¹ط§ط¯ط© طھط¹ظٹظٹظ† ظƒظ„ظ…ط© ط§ظ„ظ…ط±ظˆط±.'
                          : 'ط£ط¯ط®ظ„ ط¨ط±ظٹط¯ظƒ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ ظˆط³ظ†ط±ط³ظ„ ظ„ظƒ ط±ط§ط¨ط· ط¥ط¹ط§ط¯ط© طھط¹ظٹظٹظ† ظƒظ„ظ…ط© ط§ظ„ظ…ط±ظˆط±.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B), height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    if (!sent) ...[
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'ط§ظ„ط¨ط±ظٹط¯ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: loading ? null : submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('ط¥ط±ط³ط§ظ„ ط±ط§ط¨ط· ط§ظ„ط§ط³طھط¹ط§ط¯ط©'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('ط§ظ„ط¹ظˆط¯ط© ظ„طھط³ط¬ظٹظ„ ط§ظ„ط¯ط®ظˆظ„'),
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

