import 'package:flutter/material.dart';

import '../models/evidence.dart';
import '../services/api_service.dart';
import '../utils/indicator_picker.dart';

class EvidenceTile extends StatefulWidget {
  final Evidence evidence;
  final ApiService api;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onReject;
  final VoidCallback? onLinked;

  const EvidenceTile({
    super.key,
    required this.evidence,
    required this.api,
    this.onApprove,
    this.onReject,
    this.onLinked,
  });

  @override
  State<EvidenceTile> createState() => _EvidenceTileState();
}

class _EvidenceTileState extends State<EvidenceTile> {
  bool _busy = false;

  Future<void> _handle(Future<void> Function()? action) async {
    if (action == null || _busy) return;

    setState(() => _busy = true);

    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تنفيذ العملية: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkToIndicator() async {
    final indicatorId = await pickIndicator(context, widget.api);
    if (indicatorId == null || !mounted) return;

    await _handle(() async {
      await widget.api.linkEvidenceToIndicator(widget.evidence.id, indicatorId);
      widget.onLinked?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (widget.evidence.type) {
      'CERTIFICATE' => Icons.workspace_premium_outlined,
      'AWARD' => Icons.emoji_events_outlined,
      'ASSESSMENT' => Icons.quiz_outlined,
      'ACTIVITY' => Icons.extension_outlined,
      'PLAN' => Icons.event_note_outlined,
      'ASSIGNMENT' => Icons.assignment_outlined,
      'REPORT' => Icons.summarize_outlined,
      'INITIATIVE' => Icons.lightbulb_outlined,
      'PROJECT' => Icons.rocket_launch_outlined,
      'PRESENTATION' => Icons.slideshow_outlined,
      'IMAGE' => Icons.image_outlined,
      'VIDEO' => Icons.videocam_outlined,
      'LINK' => Icons.link_outlined,
      _ => Icons.description_outlined,
    };

    final needsReview = widget.evidence.status == 'SUGGESTED';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE6FFFB),
                  child: Icon(icon, color: const Color(0xFF0F766E)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.evidence.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.evidence.source,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: widget.evidence.status),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ConfidenceBadge(value: widget.evidence.confidence),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _busy ? null : _linkToIndicator,
                icon: const Icon(Icons.link_outlined, size: 16),
                label: const Text('ربط بمؤشر', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
              ),
            ),
            if (needsReview) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _handle(widget.onReject),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _handle(widget.onApprove),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('اعتماد'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'APPROVED' => ('معتمد', const Color(0xFF15803D)),
      'SUGGESTED' => ('بانتظار المراجعة', const Color(0xFFB45309)),
      'REJECTED' => ('مرفوض', const Color(0xFFDC2626)),
      'DUPLICATE' => ('مكرر', const Color(0xFF64748B)),
      'ARCHIVED' => ('مؤرشف', const Color(0xFF64748B)),
      _ => ('قيد الاكتشاف', const Color(0xFF64748B)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double value;

  const _ConfidenceBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(value * 100).round()}%',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
