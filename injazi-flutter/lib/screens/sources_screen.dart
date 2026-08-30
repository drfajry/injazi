import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../utils/indicator_picker.dart';

class SourcesScreen extends StatefulWidget {
  final ApiService api;

  const SourcesScreen({super.key, required this.api});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  bool _uploading = false;

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );

    final picked = result?.files.single;
    final bytes = picked?.bytes;

    if (picked == null || bytes == null) return;

    await _sendUpload(
      bytes: bytes,
      filename: picked.name,
      mimeType: _guessMimeType(picked.extension),
    );
  }

  Future<void> _capture() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    final bytes = await photo.readAsBytes();

    await _sendUpload(
      bytes: bytes,
      filename: photo.name,
      mimeType: 'image/jpeg',
    );
  }

  Future<void> _sendUpload({
    required List<int> bytes,
    required String filename,
    String? mimeType,
  }) async {
    setState(() => _uploading = true);

    try {
      final result = await widget.api.uploadFile(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
        title: filename,
      );

      if (!mounted) return;

      final data = result['data'] as Map<String, dynamic>?;
      final textExtracted = data?['textExtracted'] == true;
      final evidence = data?['evidence'] as Map<String, dynamic>?;
      final evidenceId = evidence?['id'] as String?;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            textExtracted
                ? 'تم رفع الملف واستخراج محتواه النصي وإضافته كشاهد جديد بنجاح.'
                : 'تم رفع الملف وإضافته كشاهد جديد بنجاح.',
          ),
        ),
      );

      if (evidenceId != null) {
        await _offerIndicatorAssignment(evidenceId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر رفع الملف: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _connectGoogleDrive() async {
    setState(() => _uploading = true);

    try {
      // If already connected, skip re-auth and go straight to picking files.
      final sources = await widget.api.getSources();
      final existing = sources.where((s) => s['type'] == 'GOOGLE_DRIVE').toList();

      if (existing.isNotEmpty) {
        if (mounted) setState(() => _uploading = false);
        await _openDriveFilePicker(existing.first['id'] as String);
        return;
      }

      final url = await widget.api.getGoogleAuthUrl();
      final uri = Uri.parse(url);

      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح صفحة ربط Google.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر بدء ربط Google Drive: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openDriveFilePicker(String sourceId) async {
    // Breadcrumb stack of visited folders (id + display name), so the
    // person can navigate into folders and back out — {'id': 'root',
    // 'name': 'الرئيسية'} is always the first entry.
    final folderStack = <Map<String, String>>[
      {'id': 'root', 'name': 'الرئيسية'},
    ];

    List<Map<String, dynamic>> items = [];
    bool loading = true;
    String? error;
    String? importingId;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> loadFolder() async {
            setDialogState(() {
              loading = true;
              error = null;
            });

            try {
              final fetched = await widget.api.browseDriveFolder(sourceId, folderId: folderStack.last['id']);
              setDialogState(() {
                items = fetched;
                loading = false;
              });
            } catch (e) {
              setDialogState(() {
                error = e.toString().replaceFirst('Exception: ', '');
                loading = false;
              });
            }
          }

          if (loading && error == null && items.isEmpty && folderStack.length == 1) {
            loadFolder();
          }

          void openFolder(Map<String, dynamic> folder) {
            folderStack.add({'id': folder['id'] as String, 'name': folder['title'] as String});
            items = [];
            loadFolder();
          }

          void goBack() {
            if (folderStack.length <= 1) return;
            folderStack.removeLast();
            items = [];
            loadFolder();
          }

          Future<void> importFile(Map<String, dynamic> item) async {
            setDialogState(() => importingId = item['id'] as String);

            try {
              await widget.api.importDriveFile(sourceId, item['id'] as String);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم استيراد "${item['title']}" كشاهد جديد بنجاح.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تعذّر الاستيراد: ${e.toString().replaceFirst('Exception: ', '')}')),
                );
              }
            } finally {
              setDialogState(() => importingId = null);
            }
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Row(
                children: [
                  if (folderStack.length > 1)
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      tooltip: 'رجوع',
                      onPressed: loading ? null : goBack,
                    ),
                  Expanded(
                    child: Text(
                      folderStack.last['name'] ?? 'Google Drive',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? Center(child: Text('تعذّر جلب الملفات: $error', textAlign: TextAlign.center))
                        : items.isEmpty
                            ? const Center(child: Text('هذا المجلد فارغ.'))
                            : ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final isFolder = item['isFolder'] == true;
                                  final isImporting = importingId == item['id'];
                                  final itemType = (item['itemType'] as String?) ?? '';

                                  final icon = isFolder
                                      ? Icons.folder_outlined
                                      : switch (itemType) {
                                          String t when t == 'application/pdf' => Icons.picture_as_pdf_outlined,
                                          String t when t.startsWith('image/') => Icons.image_outlined,
                                          String t when t.startsWith('video/') => Icons.videocam_outlined,
                                          String t when t.contains('word') || t.contains('document') => Icons.description_outlined,
                                          String t when t.contains('sheet') || t.contains('excel') => Icons.table_chart_outlined,
                                          String t when t.contains('zip') || t.contains('apk') => Icons.archive_outlined,
                                          _ => Icons.insert_drive_file_outlined,
                                        };

                                  final typeLabel = isFolder
                                      ? 'مجلد'
                                      : switch (itemType) {
                                          String t when t == 'application/pdf' => 'PDF',
                                          String t when t.startsWith('image/') => 'صورة',
                                          String t when t.startsWith('video/') => 'فيديو',
                                          String t when t.contains('word') || t.contains('document') => 'Word',
                                          String t when t.contains('sheet') || t.contains('excel') => 'Excel',
                                          '' => 'نوع غير معروف',
                                          _ => itemType,
                                        };

                                  return ListTile(
                                    dense: true,
                                    leading: Icon(icon, color: isFolder ? const Color(0xFFD97706) : const Color(0xFF0F766E)),
                                    title: Text(
                                      item['title'] ?? '',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(typeLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    onTap: isFolder ? () => openFolder(item) : null,
                                    trailing: isFolder
                                        ? const Icon(Icons.chevron_left, color: Color(0xFF94A3B8))
                                        : isImporting
                                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                            : IconButton(
                                                icon: const Icon(Icons.download_outlined),
                                                tooltip: 'استيراد كشاهد',
                                                onPressed: importingId != null ? null : () => importFile(item),
                                              ),
                                  );
                                },
                              ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addFixedPage() async {
    const options = {
      'CV': 'السيرة الذاتية',
      'VISION_MISSION': 'الرؤية والرسالة والأهداف',
      'SCHEDULE': 'الجدول الدراسي',
      'STUDENTS': 'بيانات الطلاب',
      'OTHER': 'أخرى',
    };

    // Written directly rather than uploaded as a file.
    const textEntryTypes = {'VISION_MISSION'};

    final chosenType = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SimpleDialog(
          title: const Text('نوع الصفحة الثابتة'),
          children: options.entries
              .map(
                (entry) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, entry.key),
                  child: Text(entry.value),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (chosenType == null || !mounted) return;

    if (textEntryTypes.contains(chosenType)) {
      await _addFixedPageAsText(chosenType, options[chosenType]!);
    } else {
      await _addFixedPageAsFile(chosenType, options[chosenType]!);
    }
  }

  Future<void> _addFixedPageAsText(String fixedPageType, String label) async {
    if (fixedPageType == 'VISION_MISSION') {
      await _addVisionMissionGoals();
      return;
    }

    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 10,
              decoration: InputDecoration(hintText: 'اكتب $label هنا...'),
            ),
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

    if (text == null || text.isEmpty || !mounted) return;

    setState(() => _uploading = true);

    try {
      await widget.api.addFixedPageText(fixedPageType: fixedPageType, label: label, text: text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة "$label" لمقدمة ملف الإنجاز.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الإضافة: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addVisionMissionGoals() async {
    final visionController = TextEditingController();
    final missionController = TextEditingController();
    final goalsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('الرؤية والرسالة والأهداف'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الرؤية', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: visionController,
                    autofocus: true,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'اكتب الرؤية هنا...'),
                  ),
                  const SizedBox(height: 16),
                  const Text('الرسالة', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: missionController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'اكتب الرسالة هنا...'),
                  ),
                  const SizedBox(height: 16),
                  const Text('الأهداف', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: goalsController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'اكتب الأهداف هنا...'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final vision = visionController.text.trim();
    final mission = missionController.text.trim();
    final goals = goalsController.text.trim();

    if (vision.isEmpty && mission.isEmpty && goals.isEmpty) return;

    // Stored as structured JSON (not plain text) so the export can render
    // each as its own labeled box on one page, instead of one long
    // undifferentiated paragraph.
    final structuredText = jsonEncode({
      'vision': vision,
      'mission': mission,
      'goals': goals,
    });

    setState(() => _uploading = true);

    try {
      await widget.api.addFixedPageText(
        fixedPageType: 'VISION_MISSION',
        label: 'الرؤية والرسالة والأهداف',
        text: structuredText,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة "الرؤية والرسالة والأهداف" لمقدمة ملف الإنجاز.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الإضافة: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addFixedPageAsFile(String fixedPageType, String label) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false, withData: true);
    final picked = result?.files.single;
    final bytes = picked?.bytes;

    if (picked == null || bytes == null || !mounted) return;

    setState(() => _uploading = true);

    try {
      await widget.api.uploadFixedPage(
        bytes: bytes,
        filename: picked.name,
        mimeType: _guessMimeType(picked.extension),
        fixedPageType: fixedPageType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة "$label" لمقدمة ملف الإنجاز.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الإضافة: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addUrl() async {
    final controller = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة من رابط'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://example.com/article',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (url == null || url.isEmpty) return;

    setState(() => _uploading = true);

    try {
      final result = await widget.api.addUrlEvidence(url);

      if (!mounted) return;

      final data = result['data'] as Map<String, dynamic>?;
      final textExtracted = data?['textExtracted'] == true;
      final evidence = data?['evidence'] as Map<String, dynamic>?;
      final evidenceId = evidence?['id'] as String?;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            textExtracted
                ? 'تم جلب محتوى الرابط وإضافته كشاهد جديد بنجاح.'
                : 'تم إضافة الرابط، لكن تعذّر استخراج محتوى نصي منه.',
          ),
        ),
      );

      if (evidenceId != null) {
        await _offerIndicatorAssignment(evidenceId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إضافة الرابط: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _offerIndicatorAssignment(String evidenceId) async {
    final indicatorId = await pickIndicator(context, widget.api);
    if (indicatorId == null || !mounted) return;

    try {
      await widget.api.linkEvidenceToIndicator(evidenceId, indicatorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم ربط الشاهد بالمؤشر المختار.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الربط بالمؤشر: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  String? _guessMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          children: [
            const Text('مصادر الإنجاز', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('اربط مصادر إنجازاتك حتى نتمكن من اكتشاف الشواهد المهنية تلقائيًا وبناء ملفك.', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 22),
            _SourceCard(icon: Icons.school_outlined, title: 'مدرستي', subtitle: 'اربط حسابك في منصة مدرستي لاستيراد الإنجازات', button: 'ربط مدرستي', onTap: () {}),
            const SizedBox(height: 12),
            _SourceCard(icon: Icons.cloud_outlined, title: 'Google Drive', subtitle: 'استورد الملفات من مساحة Google Drive الخاصة بك', button: 'ربط Google', onTap: _uploading ? null : _connectGoogleDrive),
            const SizedBox(height: 12),
            _SourceCard(icon: Icons.upload_file_outlined, title: 'رفع ملف', subtitle: 'ارفع مستنداتك مباشرة من جهازك', button: 'اختيار ملف', onTap: _uploading ? null : _uploadFile),
            const SizedBox(height: 12),
            _SourceCard(icon: Icons.camera_alt_outlined, title: 'التقاط صورة', subtitle: 'صوّر شهادة أو مستندًا مباشرة بالكاميرا', button: 'التقاط', onTap: _uploading ? null : _capture),
            const SizedBox(height: 12),
            _SourceCard(icon: Icons.link_outlined, title: 'إضافة من رابط', subtitle: 'الصق رابط مقال أو تقرير وسنستخرج محتواه تلقائيًا', button: 'إضافة رابط', onTap: _uploading ? null : _addUrl),
            const SizedBox(height: 12),
            _SourceCard(icon: Icons.badge_outlined, title: 'صفحات ثابتة', subtitle: 'ارفع ملفات جاهزة (سيرة ذاتية، جدول، رؤية ورسالة) تظهر بمقدمة ملف الإنجاز', button: 'إضافة صفحة ثابتة', onTap: _uploading ? null : _addFixedPage),
          ],
        ),
        if (_uploading)
          const Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(child: LinearProgressIndicator()),
          ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback? onTap;
  const _SourceCard({required this.icon, required this.title, required this.subtitle, required this.button, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFF0F766E))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
        ])),
        const SizedBox(width: 10),
        FilledButton(onPressed: onTap, child: Text(button)),
      ]),
    ),
  );
}
