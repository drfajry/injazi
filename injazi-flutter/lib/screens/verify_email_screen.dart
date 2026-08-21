import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final Future<void> Function() onVerified;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final codeController = TextEditingController();
  late final ApiService api;
  bool loading = false;
  bool resending = false;

  @override
  void initState() {
    super.initState();
    api = ApiService(baseUrl: 'https://injazi-backend-svxy.onrender.com');
  }

  @override
  void dispose() {
    codeController.dispose();
    api.dispose();
    super.dispose();
  }

  Future<void> verify() async {
    final code = codeController.text.trim();

    if (!RegExp(r'^\\d{6}$').hasMatch(code)) {
      _message('ط£ط¯ط®ظ„ ط±ظ…ط² ط§ظ„طھط­ظ‚ظ‚ ط§ظ„ظ…ظƒظˆظ† ظ…ظ† 6 ط£ط±ظ‚ط§ظ…');
      return;
    }

    setState(() => loading = true);

    try {
      await api.verifyEmail(
        email: widget.email,
        code: code,
      );

      await widget.onVerified();

      if (!mounted) return;
      context.go('/profile/setup');
    } catch (e) {
      if (!mounted) return;
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resend() async {
    setState(() => resending = true);

    try {
      await api.resendVerification(email: widget.email);
      if (!mounted) return;
      _message('طھظ… ط¥ط±ط³ط§ظ„ ط±ظ…ط² طھط­ظ‚ظ‚ ط¬ط¯ظٹط¯ ط¥ظ„ظ‰ ط¨ط±ظٹط¯ظƒ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ');
    } catch (e) {
      if (!mounted) return;
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => resending = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 54,
                        color: Color(0xFF0F766E),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'طھط­ظ‚ظ‚ ظ…ظ† ط¨ط±ظٹط¯ظƒ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ط£ط±ط³ظ„ظ†ط§ ط±ظ…ط² طھط­ظ‚ظ‚ ط¥ظ„ظ‰ ',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'ط±ظ…ط² ط§ظ„طھط­ظ‚ظ‚',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: loading ? null : verify,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('طھط­ظ‚ظ‚ ظ…ظ† ط§ظ„ط¨ط±ظٹط¯'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: resending ? null : resend,
                        child: resending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('ط¥ط¹ط§ط¯ط© ط¥ط±ط³ط§ظ„ ط§ظ„ط±ظ…ط²'),
                      ),
                      const SizedBox(height: 8),
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
      ),
    );
  }
}

