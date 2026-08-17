import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
const ForgotPasswordScreen({super.key});

@override
State<ForgotPasswordScreen> createState() =>
_ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
extends State<ForgotPasswordScreen> {
final emailController = TextEditingController();

late final ApiService api;

bool loading = false;
bool sent = false;

@override
void initState() {
super.initState();

```
api = ApiService(
  baseUrl: 'https://injazi-backend-svxy.onrender.com',
);
```

}

@override
void dispose() {
emailController.dispose();
api.dispose();
super.dispose();
}

Future<void> submit() async {
final email = emailController.text.trim();

```
if (email.isEmpty) {
  _showMessage(
    '\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
  );
  return;
}

setState(() {
  loading = true;
});

try {
  await api.forgotPassword(email: email);

  if (!mounted) return;

  setState(() {
    sent = true;
  });
} catch (error) {
  if (!mounted) return;

  _showMessage(
    error.toString().replaceFirst('Exception: ', ''),
  );
} finally {
  if (mounted) {
    setState(() {
      loading = false;
    });
  }
}
```

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
crossAxisAlignment:
CrossAxisAlignment.stretch,
children: [
const Icon(
Icons.lock_reset_outlined,
size: 54,
color: Color(0xFF0F766E),
),
const SizedBox(height: 18),
Text(
sent
? '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0627\u0628\u0637'
: '\u0646\u0633\u064a\u062a \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631\u061f',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 27,
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 10),
Text(
sent
? '\u0625\u0630\u0627 \u0643\u0627\u0646 \u0627\u0644\u0628\u0631\u064a\u062f \u0645\u0633\u062c\u0644\u064b\u0627 \u0644\u062f\u064a\u0646\u0627\u060c \u0641\u0633\u064a\u0635\u0644\u0643 \u0631\u0627\u0628\u0637 \u0644\u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631.'
: '\u0623\u062f\u062e\u0644 \u0628\u0631\u064a\u062f\u0643 \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u0644\u062a\u0635\u0644\u0643 \u0625\u0631\u0633\u0627\u0644\u0629 \u0628\u0631\u0627\u0628\u0637 \u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631.',
textAlign: TextAlign.center,
style: const TextStyle(
height: 1.6,
color: Color(0xFF64748B),
),
),
const SizedBox(height: 24),
if (!sent) ...[
TextField(
controller: emailController,
keyboardType:
TextInputType.emailAddress,
textDirection: TextDirection.ltr,
decoration:
const InputDecoration(
labelText:
'\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
prefixIcon:
Icon(Icons.email_outlined),
border: OutlineInputBorder(),
),
),
const SizedBox(height: 18),
FilledButton(
onPressed: loading ? null : submit,
child: Padding(
padding:
const EdgeInsets.symmetric(
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
'\u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0627\u0628\u0637',
),
),
),
],
const SizedBox(height: 14),
TextButton(
onPressed: () => context.go('/login'),
child: const Text(
'\u0627\u0644\u0639\u0648\u062f \u0625\u0644\u0649 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',
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
