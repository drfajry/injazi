import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProgressReportScreen extends StatefulWidget {
  final ApiService api;

  const ProgressReportScreen({super.key, required this.api});

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _timeline = const [];
  List<Map<String, dynamic>> _criteria = const [];
  int _totalIndicators = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.api.getProgressReport();

      if (!mounted) return;

      setState(() {
        _timeline = List<Map<String, dynamic>>.from(
          (data['timeline'] as List).map((t) => Map<String, dynamic>.from(t)),
        );
        _criteria = List<Map<String, dynamic>>.from(
          (data['criteria'] as List).map((c) => Map<String, dynamic>.from(c)),
        );
        _totalIndicators = (data['totalIndicators'] ?? 0) as int;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تقارير التقدم')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
                          const SizedBox(height: 12),
                          Text('تعذّر تحميل التقرير: $_error', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        const Text('تقدّمك بمرور الوقت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          'عدد المؤشرات المغطاة تراكميًا من إجمالي $_totalIndicators',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        _timeline.isEmpty
                            ? Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'لا توجد بيانات كافية بعد — ارفع شواهد أكثر عشان يظهر التقدم هنا.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                              )
                            : Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: SizedBox(
                                    height: 200,
                                    child: CustomPaint(
                                      size: Size.infinite,
                                      painter: _TimelinePainter(
                                        timeline: _timeline,
                                        totalIndicators: _totalIndicators,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 26),
                        const Text('مقارنة المعايير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text(
                          'أي معيار أقوى وأيها يحتاج تركيز أكثر',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        ..._criteria.map((criterion) => _CriterionBar(criterion: criterion)),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<Map<String, dynamic>> timeline;
  final int totalIndicators;

  _TimelinePainter({required this.timeline, required this.totalIndicators});

  @override
  void paint(Canvas canvas, Size size) {
    if (timeline.isEmpty || totalIndicators == 0) return;

    const leftPadding = 34.0;
    const bottomPadding = 24.0;
    final chartWidth = size.width - leftPadding - 8;
    final chartHeight = size.height - bottomPadding - 8;

    final axisPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    // Horizontal gridlines at 0%, 50%, 100%.
    final textPainterStyle = const TextStyle(fontSize: 9, color: Color(0xFF94A3B8));
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = 8 + chartHeight * (1 - fraction);
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), axisPaint);

      final label = '${(fraction * 100).round()}%';
      final tp = TextPainter(
        text: TextSpan(text: label, style: textPainterStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Line path across timeline points.
    final points = <Offset>[];
    for (var i = 0; i < timeline.length; i++) {
      final percent = ((timeline[i]['percent'] ?? 0) as num).toDouble() / 100;
      final x = timeline.length == 1
          ? leftPadding + chartWidth
          : leftPadding + (chartWidth * i / (timeline.length - 1));
      final y = 8 + chartHeight * (1 - percent.clamp(0, 1));
      points.add(Offset(x, y));
    }

    if (points.length == 1) {
      // Single data point — draw just a dot, no line needed.
      canvas.drawCircle(points.first, 4, Paint()..color = const Color(0xFF359B77));
      return;
    }

    final linePaint = Paint()
      ..color = const Color(0xFF359B77)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);

    // Fill area under the line for a nicer "growth" look.
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, 8 + chartHeight)
      ..lineTo(points.first.dx, 8 + chartHeight)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = const Color(0xFF359B77).withValues(alpha: 0.08),
    );

    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = const Color(0xFF359B77));
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.timeline != timeline || oldDelegate.totalIndicators != totalIndicators;
  }
}

class _CriterionBar extends StatelessWidget {
  final Map<String, dynamic> criterion;

  const _CriterionBar({required this.criterion});

  @override
  Widget build(BuildContext context) {
    final percent = ((criterion['percent'] ?? 0) as num).toDouble();
    final covered = criterion['covered'] ?? 0;
    final total = criterion['total'] ?? 0;

    final color = percent < 35
        ? const Color(0xFFEF4444)
        : percent < 90
            ? const Color(0xFFF59E0B)
            : const Color(0xFF15803D);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  criterion['name'] ?? '',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$covered/$total',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: total > 0 ? covered / total : 0,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
