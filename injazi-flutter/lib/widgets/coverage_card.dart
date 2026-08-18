import 'package:flutter/material.dart';

class CoverageCard extends StatelessWidget {
  final double value;
  final int complete;
  final int needsSupport;
  final int missing;

  const CoverageCard({super.key, required this.value, required this.complete, required this.needsSupport, required this.missing});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF0F766E), Color(0xFF115E59)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ظ…ظ„ظپ ط¥ظ†ط¬ط§ط²ظٹ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
          const Padding(padding: EdgeInsets.only(bottom: 8, right: 8), child: Text('ظ…ظƒطھظ…ظ„', style: TextStyle(color: Colors.white70))),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: value, minHeight: 9, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 8, children: [
          _Pill('$complete ظ…ظƒطھظ…ظ„'),
          _Pill('$needsSupport ظٹط­طھط§ط¬ ط¯ط¹ظ…'),
          _Pill('$missing ط¨ط¯ظˆظ† ط¯ظ„ظٹظ„'),
        ])
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(30)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
  );
}


