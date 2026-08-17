import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
final VoidCallback onStart;

const LandingScreen({
super.key,
required this.onStart,
});

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: const Color(0xFFF7F9FC),
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(
horizontal: 24,
vertical: 20,
),
child: Column(
children: [
Row(
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: const Color(0xFFE6FFFB),
borderRadius: BorderRadius.circular(15),
),
child: const Icon(
Icons.auto_awesome,
color: Color(0xFF0F766E),
),
),
const SizedBox(width: 12),
const Text(
'\u0625\u0646\u062c\u0627\u0632\u064a',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.w900,
color: Color(0xFF172033),
),
),
const Spacer(),
TextButton(
onPressed: onStart,
child: const Text(
'\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',
),
),
],
),
const SizedBox(height: 42),
Container(
width: 92,
height: 92,
decoration: BoxDecoration(
color: const Color(0xFFE6FFFB),
borderRadius: BorderRadius.circular(28),
),
child: const Icon(
Icons.auto_awesome,
size: 48,
color: Color(0xFF0F766E),
),
),
const SizedBox(height: 24),
const Text(
'\u0645\u0644\u0641 \u0625\u0646\u062c\u0627\u0632\u0643\u060c \u0628\u0630\u0643\u0627\u0621',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 38,
height: 1.2,
fontWeight: FontWeight.w900,
color: Color(0xFF172033),
),
),
const SizedBox(height: 16),
const Text(
'\u0625\u0646\u062c\u0627\u0632\u064a \u0645\u0646\u0635\u0629 \u0630\u0643\u064a\u0629 \u062a\u0633\u0627\u0639\u062f \u0627\u0644\u0645\u0639\u0644\u0645 \u0639\u0644\u0649 \u062c\u0645\u0639 \u0623\u062f\u0644\u062a\u0647\u060c \u062a\u0631\u062a\u064a\u0628 \u0645\u0644\u0641\u0647\u060c \u0648\u0645\u062a\u0627\u0628\u0639\u0629 \u0645\u062f\u0649 \u0627\u0643\u062a\u0645\u0627\u0644\u0647.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 17,
height: 1.7,
color: Color(0xFF64748B),
),
),
const SizedBox(height: 28),
FilledButton(
onPressed: onStart,
style: FilledButton.styleFrom(
minimumSize: const Size(
double.infinity,
56,
),
backgroundColor: const Color(0xFF0F766E),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
),
child: const Text(
'\u0627\u0628\u062f\u0623 \u0627\u0644\u0622\u0646',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w800,
),
),
),
const SizedBox(height: 42),
const Row(
children: [
Expanded(
child: _FeatureCard(
icon: Icons.auto_graph_outlined,
title:
'\u0627\u0644\u062a\u0642\u062f\u0645 \u0627\u0644\u0630\u0643\u064a',
description:
'\u062a\u0627\u0628\u0639 \u0646\u0633\u0628\u0629 \u0627\u0643\u062a\u0645\u0627\u0644 \u0645\u0644\u0641\u0643 \u0628\u0635\u0648\u0631\u0629 \u0648\u0627\u0636\u062d\u0629.',
),
),
SizedBox(width: 12),
Expanded(
child: _FeatureCard(
icon: Icons.folder_open_outlined,
title:
'\u062c\u0645\u0639 \u0627\u0644\u0623\u062f\u0644\u0629',
description:
'\u062c\u0645\u0639 \u0648\u062a\u0635\u0646\u064a\u0641 \u0623\u062f\u0644\u062a\u0643 \u0641\u064a \u0645\u0643\u0627\u0646 \u0648\u0627\u062d\u062f.',
),
),
SizedBox(width: 12),
Expanded(
child: _FeatureCard(
icon: Icons.description_outlined,
title:
'\u0645\u0644\u0641 \u0645\u0646\u0638\u0645',
description:
'\u0627\u0644\u0627\u0633\u062a\u0639\u062f\u0627\u062f \u0644\u0639\u0631\u0636 \u0645\u0644\u0641 \u0625\u0646\u062c\u0627\u0632\u0643 \u0628\u0633\u0647\u0648\u0644\u0629.',
),
),
],
),
const SizedBox(height: 30),
const Text(
'\u0627\u0644\u0628\u062f\u0627\u064a\u0629 \u0645\u062c\u0627\u0646\u064a\u0629',
style: TextStyle(
color: Color(0xFF64748B),
fontWeight: FontWeight.w600,
),
),
],
),
),
),
),
);
}
}

class _FeatureCard extends StatelessWidget {
final IconData icon;
final String title;
final String description;

const _FeatureCard({
required this.icon,
required this.title,
required this.description,
});

@override
Widget build(BuildContext context) {
return Card(
child: Padding(
padding: const EdgeInsets.all(18),
child: Column(
children: [
Icon(
icon,
size: 30,
color: const Color(0xFF0F766E),
),
const SizedBox(height: 12),
Text(
title,
textAlign: TextAlign.center,
style: const TextStyle(
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
Text(
description,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 13,
height: 1.5,
color: Color(0xFF64748B),
),
),
],
),
),
);
}
}
