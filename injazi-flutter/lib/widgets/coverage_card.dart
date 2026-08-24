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

  // Coverage-level color coding for the progress bar fill: red below 35%,
  // amber 35–89.9%, green from 90% and up — a quick visual read of how far
  // along the portfolio is, without needing to read the number itself.
  Color get _barColor {
    final percent = value * 100;
    if (percent < 35) return const Color(0xFFEF4444); // red
    if (percent < 90) return const Color(0xFFF59E0B); // amber
    return const Color(0xFF4ADE80); // green
  }

  @override
  Widget build(BuildContext context) {
    // Show one decimal place instead of rounding to a whole number: with
    // only a handful of indicators matched out of 53 total, the true
    // percentage is often under 1% — rounding that to "0%" looks like no
    // progress happened at all, even when evidence has been matched.
    final percent = value * 100;
    final percentLabel = percent < 10 ? percent.toStringAsFixed(1) : percent.round().toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF0F766E),
            Color(0xFF115E59),
          ],
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
          const SizedBox(height: 14),
          _CoverageBar(value: value, color: _barColor),
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

class _CoverageBar extends StatelessWidget {
  final double value;
  final Color color;

  const _CoverageBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return SizedBox(
          height: 16,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerRight,
            children: [
              // Track
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              // Fill — subtle in-hue gradient plus a soft glow instead of a
              // flat single-color bar, so the edge doesn't look like an
              // abrupt cut-off.
              FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: clamped,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.75), color],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 8,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
              // Threshold markers at 35% and 90%, so the color transitions
              // read as meaningful checkpoints rather than an arbitrary cut.
              for (final threshold in [0.35, 0.90])
                Positioned(
                  right: (width * threshold).clamp(0.0, width) - 0.5,
                  child: Container(
                    width: 1,
                    height: 16,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
        );
      },
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