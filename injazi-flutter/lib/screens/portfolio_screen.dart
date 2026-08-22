import 'package:flutter/material.dart';

import '../services/api_service.dart';

class PortfolioScreen extends StatefulWidget {
  final ApiService api;

  const PortfolioScreen({super.key, required this.api});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool _loading = true;
  bool _generating = false;
  String? _error;
  List<Map<String, dynamic>> _sections = const [];
  int _totalIndicators = 0;
  int _coveredIndicators = 0;
  double _overallCoverage = 0;

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
      final data = await widget.api.getPortfolioPreview();

      if (!mounted) return;

      setState(() {
        _sections = List<Map<String, dynamic>>.from(
          (data['sections'] as List).map((s) => Map<String, dynamic>.from(s)),
        );
        _totalIndicators = (data['totalIndicators'] ?? 0) as int;
        _coveredIndicators = (data['coveredIndicators'] ?? 0) as int;
        _overallCoverage = ((data['overallCoverage'] ?? 0) as num).toDouble();
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

  Future<void> _generate() async {
    setState(() => _generating = true);

    try {
      await widget.api.generatePortfolio();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء نسخة جديدة من ملف الإنجاز.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إنشاء ملف الإنجاز: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
              const SizedBox(height: 12),
              Text('تعذّر تحميل ملف الإنجاز: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    final percentLabel = _overallCoverage * 100 < 10
        ? (_overallCoverage * 100).toStringAsFixed(1)
        : (_overallCoverage * 100).round().toString();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        children: [
          const Text('ملف الإنجاز', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('تقدّمك موزّع على 11 معيارًا رسميًا و53 مؤشرًا فرعيًا.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$percentLabel%',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, right: 8),
                      child: Text('$_coveredIndicators من $_totalIndicators مؤشر مغطى', style: const TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _generating ? null : _generate,
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F766E)),
                    icon: _generating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_outlined),
                    label: const Text('إنشاء نسخة جديدة'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('المعايير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ..._sections.map((section) => _CriterionCard(section: section)),
        ],
      ),
    );
  }
}

class _CriterionCard extends StatelessWidget {
  final Map<String, dynamic> section;

  const _CriterionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final total = (section['totalIndicators'] ?? 0) as int;
    final covered = (section['coveredIndicators'] ?? 0) as int;
    final indicators = List<Map<String, dynamic>>.from(
      (section['indicators'] as List? ?? []).map((i) => Map<String, dynamic>.from(i)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(section['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$covered من $total مؤشر مغطى', style: const TextStyle(color: Color(0xFF64748B))),
        leading: CircleAvatar(
          backgroundColor: covered > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
          child: Text(
            total == 0 ? '0%' : '${((covered / total) * 100).round()}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: covered > 0 ? const Color(0xFF15803D) : const Color(0xFF64748B)),
          ),
        ),
        children: indicators.map((indicator) {
          final evidenceList = List<Map<String, dynamic>>.from(
            (indicator['evidence'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
          );
          final hasEvidence = evidenceList.isNotEmpty;

          return ListTile(
            dense: true,
            leading: Icon(
              hasEvidence ? Icons.check_circle : Icons.radio_button_unchecked,
              color: hasEvidence ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
              size: 20,
            ),
            title: Text(indicator['name'] ?? '', style: const TextStyle(fontSize: 13)),
            subtitle: hasEvidence
                ? Text(
                    evidenceList.map((e) => e['title']).join('، '),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  )
                : const Text('لا يوجد دليل مرتبط بعد', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
          );
        }).toList(),
      ),
    );
  }
}
