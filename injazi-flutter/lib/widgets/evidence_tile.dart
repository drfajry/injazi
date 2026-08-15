import 'package:flutter/material.dart';
import '../models/evidence.dart';

class EvidenceTile extends StatelessWidget {
  final Evidence evidence;
  const EvidenceTile({super.key, required this.evidence});

  @override
  Widget build(BuildContext context) {
    final icon = switch (evidence.type) {
      'شهادة' => Icons.workspace_premium_outlined,
      'اختبار' => Icons.quiz_outlined,
      'نشاط' => Icons.extension_outlined,
      _ => Icons.description_outlined,
    };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE6FFFB),
          child: Icon(icon, color: const Color(0xFF0F766E)),
        ),
        title: Text(evidence.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${evidence.type} • ${evidence.source}', style: const TextStyle(color: Color(0xFF64748B))),
        trailing: _ConfidenceBadge(value: evidence.confidence),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double value;
  const _ConfidenceBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
