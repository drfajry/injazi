import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../utils/file_preview_web.dart';

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

  bool _exporting = false;

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);

    try {
      final htmlBytes = await widget.api.getPortfolioExportHtml();
      previewFileInNewTab(htmlBytes, 'text/html', 'ملف_الإنجاز.html');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فُتحت صفحة الملف بتبويب جديد — اضغط Ctrl+P واختر "حفظ كـ PDF".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تجهيز الملف: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  bool _sharing = false;

  Future<void> _shareLink() async {
    setState(() => _sharing = true);

    try {
      final url = await widget.api.publishPortfolio();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('رابط المشاركة العام'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'هذا الرابط يعرض نسبة الإنجاز والمعايير المغطاة فقط — بدون تفاصيل الشواهد. أي شخص يملك الرابط يقدر يفتحه بدون تسجيل دخول.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                SelectableText(url, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الرابط.')),
                  );
                },
                child: const Text('نسخ الرابط'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _unshareLink();
                },
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                child: const Text('إلغاء المشاركة'),
              ),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تم')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إنشاء رابط المشاركة: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _unshareLink() async {
    try {
      await widget.api.unpublishPortfolio();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء رابط المشاركة.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إلغاء المشاركة: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  bool _sharingWithColleague = false;

  Future<void> _shareWithColleague() async {
    setState(() => _sharingWithColleague = true);

    try {
      final url = await widget.api.shareWithColleague();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('مشاركة مع زميل'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'هذا الرابط يعرض ملفك كامل بالشواهد الحقيقية — أرسله لزميل تثق فيه بس، ما ننصح تنشره بشكل عام. أي شخص يملك الرابط يقدر يفتحه بدون تسجيل دخول.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                SelectableText(url, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الرابط.')),
                  );
                },
                child: const Text('نسخ الرابط'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _stopSharingWithColleague();
                },
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                child: const Text('إلغاء المشاركة'),
              ),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تم')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إنشاء رابط المشاركة: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _sharingWithColleague = false);
    }
  }

  Future<void> _stopSharingWithColleague() async {
    try {
      await widget.api.stopSharingWithColleague();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء رابط المشاركة مع الزميل.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إلغاء المشاركة: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
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
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _generating ? null : _generate,
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F766E)),
                        icon: _generating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.auto_awesome_outlined),
                        label: const Text('نسخة جديدة'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exporting ? null : _exportPdf,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                        icon: _exporting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('تصدير PDF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _sharing ? null : _shareLink,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                    icon: _sharing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.share_outlined),
                    label: const Text('مشاركة رابط عام'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _sharingWithColleague ? null : _shareWithColleague,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                    icon: _sharingWithColleague
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.person_outline),
                    label: const Text('مشاركة مع زميل (كامل الشواهد)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('المعايير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ..._sections.map((section) => _CriterionCard(section: section, api: widget.api, allSections: _sections, onChanged: _load)),
        ],
      ),
    );
  }
}

class _CriterionCard extends StatefulWidget {
  final Map<String, dynamic> section;
  final ApiService api;
  final List<Map<String, dynamic>> allSections;
  final VoidCallback onChanged;

  const _CriterionCard({
    required this.section,
    required this.api,
    required this.allSections,
    required this.onChanged,
  });

  @override
  State<_CriterionCard> createState() => _CriterionCardState();
}

class _CriterionCardState extends State<_CriterionCard> {
  String? _loadingFileId;

  Future<void> _openFile(String fileId) async {
    setState(() => _loadingFileId = fileId);

    try {
      final file = await widget.api.downloadEvidenceFile(fileId);
      previewFileInNewTab(Uint8List.fromList(file.bytes), file.mimeType, file.filename);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر فتح الملف: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _loadingFileId = null);
    }
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الشاهد نهائيًا'),
          content: const Text('سيُحذف هذا الشاهد وكل ارتباطاته بالمؤشرات نهائيًا. لا يمكن التراجع عن هذا الإجراء.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveToAnotherIndicator(String evidenceId, String currentIndicatorId) async {
    final allIndicators = <Map<String, String>>[];
    for (final section in widget.allSections) {
      for (final indicator in (section['indicators'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(indicator);
        allIndicators.add({
          'id': map['id'] as String,
          'name': '${section['name']} — ${map['name']}',
        });
      }
    }

    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SimpleDialog(
          title: const Text('اختر المؤشر الصحيح'),
          children: allIndicators.map((indicator) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, indicator['id']),
              child: Text(indicator['name'] ?? '', style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
        ),
      ),
    );

    if (chosen == null) return;

    await _runAction(() async {
      await widget.api.linkEvidenceToIndicator(evidenceId, chosen);
      await widget.api.unlinkEvidenceFromIndicator(evidenceId, currentIndicatorId);
    });
  }

  Future<void> _renameEvidence(Map<String, dynamic> evidence) async {
    final controller = TextEditingController(text: evidence['title'] as String? ?? '');

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل عنوان الشاهد'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'اكتب عنوانًا واضحًا يميّز هذا الشاهد'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (newTitle == null || newTitle.isEmpty) return;

    await _runAction(() => widget.api.renameEvidence(evidence['id'] as String, newTitle));
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تنفيذ العملية: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
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
          final indicatorId = indicator['id'] as String;

          return ListTile(
            dense: true,
            leading: Icon(
              hasEvidence ? Icons.check_circle : Icons.radio_button_unchecked,
              color: hasEvidence ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
              size: 20,
            ),
            title: Text(indicator['name'] ?? '', style: const TextStyle(fontSize: 13)),
            subtitle: hasEvidence
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: evidenceList.map((e) {
                        final fileId = e['fileId'] as String?;
                        final isLoading = _loadingFileId == fileId;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: fileId == null || isLoading ? null : () => _openFile(fileId),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: isLoading
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Icon(fileId != null ? Icons.visibility_outlined : Icons.link_outlined, size: 16, color: const Color(0xFF0F766E)),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e['title'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.drive_file_rename_outline, size: 17),
                                color: const Color(0xFF64748B),
                                tooltip: 'تعديل العنوان',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _renameEvidence(e),
                              ),
                              IconButton(
                                icon: const Icon(Icons.swap_horiz, size: 17),
                                color: const Color(0xFF64748B),
                                tooltip: 'نقل إلى مؤشر آخر',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _moveToAnotherIndicator(e['id'] as String, indicatorId),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFDC2626)),
                                tooltip: 'حذف',
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'unlink', child: Text('إزالة من هذا المؤشر فقط')),
                                  const PopupMenuItem(value: 'delete', child: Text('حذف الشاهد نهائيًا')),
                                ],
                                onSelected: (value) async {
                                  final evidenceId = e['id'] as String;
                                  if (value == 'unlink') {
                                    await _runAction(() => widget.api.unlinkEvidenceFromIndicator(evidenceId, indicatorId));
                                  } else if (value == 'delete') {
                                    final confirmed = await _confirmDelete();
                                    if (confirmed == true) {
                                      await _runAction(() => widget.api.deleteEvidence(evidenceId));
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const Text('لا يوجد شاهد مرتبط بعد', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
          );
        }).toList(),
      ),
    );
  }
}
