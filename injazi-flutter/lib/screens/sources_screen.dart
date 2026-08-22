import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

class SourcesScreen extends StatefulWidget {
  final ApiService api;

  const SourcesScreen({super.key, required this.api});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  bool _uploading = false;

  Future<void> _uploadFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );

    final picked = result?.files.single;
    final bytes = picked?.bytes;

    if (picked == null || bytes == null) return;

    await _sendUpload(
      context: context,
      bytes: bytes,
      filename: picked.name,
      mimeType: _guessMimeType(picked.extension),
    );
  }

  Future<void> _capture(BuildContext context) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    final bytes = await photo.readAsBytes();

    await _sendUpload(
      context: context,
      bytes: bytes,
      filename: photo.name,
      mimeType: 'image/jpeg',
    );
  }

  Future<void> _sendUpload({
    required BuildContext context,
    required List<int> bytes,
    required String filename,
    String? mimeType,
  }) async {
    setState(() => _uploading = true);

    try {
      await widget.api.uploadFile(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
        title: filename,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الملف وإضافته كدليل جديد بنجاح.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر رفع الملف: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
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
            const Text('اربط مصادر إنجازاتك حتى نتمكن من اكتشاف الأدلة المهنية تلقائيًا وبناء ملفك.', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 22),
            _SourceCard(icon: Icons.school_outlined, title: 'منصتي', subtitle: 'اربط حسابك في منصة مدرستي لاستيراد الإنجازات', button: 'ربط منصتي', onTap: () {}),
            const SizedBox(height: 12),
            _SourceCard(icon: Icons.cloud_outlined, title: 'Google Drive', subtitle: 'استورد الملفات من مساحة Google Drive الخاصة بك', button: 'ربط Google', onTap: () {}),
            const SizedBox(height: 12),
            _SourceCard(icon: Icons.upload_file_outlined, title: 'رفع ملف', subtitle: 'ارفع مستنداتك مباشرة من جهازك', button: 'اختيار ملف', onTap: _uploading ? null : () => _uploadFile(context)),
            const SizedBox(height: 12),
            _SourceCard(icon: Icons.camera_alt_outlined, title: 'التقاط صورة', subtitle: 'صوّر شهادة أو مستندًا مباشرة بالكاميرا', button: 'التقاط', onTap: _uploading ? null : () => _capture(context)),
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
