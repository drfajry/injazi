import 'package:flutter/material.dart';

class CoverageCard extends StatelessWidget {
  final double value;
  final int complete;
  final int needsSupport;
  final int missing;

  const CoverageCard({
    super.key,
    required this.value,
    required this.complete,
    required this.needsSupport,
    required this.missing,
  });

  // Coverage-level color coding: red below 35%, yellow/amber 35–90%, green
  // above 90% — a quick visual read of how far along the portfolio is,
  // without needing to read the number itself.
  (Color, Color) get _gradientColors {
    final percent = value * 100;
    if (percent < 35) return (const Color(0xFFDC2626), const Color(0xFF991B1B)); // red
    if (percent < 90) return (const Color(0xFFD97706), const Color(0xFF92400E)); // amber
    return (const Color(0xFF15803D), const Color(0xFF14532D)); // green
  }

  @override
  Widget build(BuildContext context) {
    // Show one decimal place instead of rounding to a whole number: with
    // only a handful of indicators matched out of 53 total, the true
    // percentage is often under 1% — rounding that to "0%" looks like no
    // progress happened at all, even when evidence has been matched.
    final percent = value * 100;
    final percentLabel = percent < 10 ? percent.toStringAsFixed(1) : percent.round().toString();
    final (startColor, endColor) = _gradientColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [startColor, endColor],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نسبة التغطية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percentLabel%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(
                  bottom: 8,
                  right: 8,
                ),
                child: Text(
                  'من الملف',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Pill(
                '$complete مكتمل',
              ),
              _Pill(
                '$needsSupport بحاجة للدعم',
              ),
              _Pill(
                '$missing مفقود',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}