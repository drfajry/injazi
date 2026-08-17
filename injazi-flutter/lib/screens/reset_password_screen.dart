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
State<ResetPasswordScreen> createState() =>
_ResetPasswordScreenState();
}

class _ResetPasswordScreenState
extends State<ResetPasswordScreen> {
final passwordController = TextEditingController();
final confirmController = TextEditingController();

late final ApiService api;

bool loading = false;
bool obscurePassword = true;
bool obscureConfirm = true;

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
passwordController.dispose();
confirmController.dispose();
api.dispose();
super.dispose();
}

Future<void> submit() async {
final password = passwordController.text;
final confirm = confirmController.text;

```
if (password.length < 8) {
  _showMessage(
    '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u064a\u062c\u0628 \u0623\u0646 \u062a\u0643\u0648\u0646 8 \u0623\u062d\u0631\u0641 \u0648\u0623\u0631\u0642\u0627\u0645 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644',
  );
  return;
}

if (password != confirm) {
  _showMessage(
    '\u0643\u0644\u0645\u062a\u0627 \u0627\u0644\u0645\u0631\u0648\u0631 \u063a\u064a\u0631 \u0645\u062a\u0637\u0627\u0628\u0642\u062a\u064a\u0646',
  );
  return;
}

setState(() {
  loading = true;
});

try {
  await api.resetPassword(
    token: widget.token,
    password: password,
  );

  if (!mounted) return;

  context.go('/dashboard');
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
Icons.lock_outline,
size: 54,
color: Color(0xFF0F766E),
),
const SizedBox(height: 18),
const Text(
'\u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 26,
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 24),
TextField(
controller: passwordController,
obscureText: obscurePassword,
decoration: InputDecoration(
labelText:
'\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u062c\u062f\u064a\u062f\u0629',
prefixIcon:
const Icon(Icons.lock_outline),
suffixIcon: IconButton(
onPressed: () {
setState(() {
obscurePassword =
!obscurePassword;
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
const SizedBox(height: 14),
TextField(
controller: confirmController,
obscureText: obscureConfirm,
decoration: InputDecoration(
labelText:
'\u062a\u0623\u0643\u064a\u062f \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
prefixIcon:
const Icon(Icons.lock_outline),
suffixIcon: IconButton(
onPressed: () {
setState(() {
obscureConfirm =
!obscureConfirm;
});
},
icon: Icon(
obscureConfirm
? Icons.visibility_outlined
: Icons.visibility_off_outlined,
),
),
border: const OutlineInputBorder(),
),
),
const SizedBox(height: 20),
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
'\u062d\u0641\u0638 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
),
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
