import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

/// Fetches reminders and shows them as small dismissible cards. Dismissing
/// a reminder hides it for 24 hours (stored locally via SharedPreferences)
/// rather than forever — a real gap (e.g. an empty criterion) shouldn't
/// disappear permanently just because it was dismissed once.
class RemindersBanner extends StatefulWidget {
  final ApiService api;

  const RemindersBanner({super.key, required this.api});

  @override
  State<RemindersBanner> createState() => _RemindersBannerState();
}

class _RemindersBannerState extends State<RemindersBanner> {
  Map<String, dynamic>? _reminders;
  Map<String, int> _dismissedUntil = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('dismissed_reminders');
      final dismissed = stored != null
          ? Map<String, int>.from(jsonDecode(stored) as Map)
          : <String, int>{};

      final data = await widget.api.getReminders();

      if (!mounted) return;
      setState(() {
        _reminders = data;
        _dismissedUntil = dismissed;
      });
    } catch (_) {
      // Reminders are a nice-to-have — a failure here shouldn't disrupt the
      // rest of the dashboard, so we just show nothing.
    }
  }

  Future<void> _dismiss(String key) async {
    final until = DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
    setState(() => _dismissedUntil[key] = until);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dismissed_reminders', jsonEncode(_dismissedUntil));
  }

  bool _isDismissed(String key) {
    final until = _dismissedUntil[key];
    return until != null && until > DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    final reminders = _reminders;
    if (reminders == null) return const SizedBox.shrink();

    final cards = <Widget>[];

    final emptyCriteria = List<Map<String, dynamic>>.from(
      (reminders['emptyCriteria'] as List? ?? []).map((c) => Map<String, dynamic>.from(c)),
    );
    if (emptyCriteria.isNotEmpty && !_isDismissed('empty_criteria')) {
      final names = emptyCriteria.take(2).map((c) => c['name']).join('، ');
      final extra = emptyCriteria.length > 2 ? ' و${emptyCriteria.length - 2} غيرها' : '';
      cards.add(
        _ReminderCard(
          icon: Icons.playlist_add_check_circle_outlined,
          color: const Color(0xFFD97706),
          text: 'عندك ${emptyCriteria.length} معيار لسا فاضي تمامًا: $names$extra',
          onDismiss: () => _dismiss('empty_criteria'),
        ),
      );
    }

    if (reminders['showUploadReminder'] == true && !_isDismissed('upload_gap')) {
      final days = reminders['daysSinceLastUpload'];
      final text = days == null
          ? 'ما رفعت أي شاهد بعد — ابدأ برفع أول شاهد من تبويب المصادر.'
          : 'مرّ عليك $days يوم بدون رفع أي شاهد جديد.';
      cards.add(
        _ReminderCard(
          icon: Icons.schedule_outlined,
          color: const Color(0xFF64748B),
          text: text,
          onDismiss: () => _dismiss('upload_gap'),
        ),
      );
    }

    if (reminders['showSemesterReminder'] == true && !_isDismissed('semester_end')) {
      final days = reminders['daysUntilSemesterEnd'];
      cards.add(
        _ReminderCard(
          icon: Icons.event_busy_outlined,
          color: const Color(0xFFDC2626),
          text: 'باقي $days يوم على نهاية الفصل الدراسي — تأكد ملفك مكتمل.',
          onDismiss: () => _dismiss('semester_end'),
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...cards,
        const SizedBox(height: 6),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onDismiss;

  const _ReminderCard({
    required this.icon,
    required this.color,
    required this.text,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600)),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: color.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
