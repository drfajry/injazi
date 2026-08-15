import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  Future<void> _uploadFile(BuildContext context) async {
    await FilePicker.platform.pickFiles(allowMultiple: false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم اختيار الملف. سنربطه بالـAPI لاحقًا.')));
    }
  }

  Future<void> _capture(BuildContext context) async {
    final picker = ImagePicker();
    await picker.pickImage(source: ImageSource.camera);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التقاط الصورة. سنرفعها للـAPI لاحقًا.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
      children: [
        const Text('مصادر الأدلة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('اربط مصادرك مرة واحدة، وإنجازي يبحث عن الأدلة نيابةً عنك.', style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 22),
        _SourceCard(icon: Icons.school_outlined, title: 'مدرستي', subtitle: 'اكتشاف أعمالك التعليمية تلقائيًا', button: 'ربط مدرستي', onTap: () {}),
        const SizedBox(height: 12),
        _SourceCard(icon: Icons.cloud_outlined, title: 'Google Drive', subtitle: 'البحث عن ملفاتك التعليمية', button: 'ربط Google', onTap: () {}),
        const SizedBox(height: 12),
        _SourceCard(icon: Icons.upload_file_outlined, title: 'رفع يدوي', subtitle: 'شهادة، صورة، ملف أو رابط', button: 'اختيار ملف', onTap: () => _uploadFile(context)),
        const SizedBox(height: 12),
        _SourceCard(icon: Icons.camera_alt_outlined, title: 'تصوير شهادة', subtitle: 'التقاط شهادة وسيقرأها الذكاء الاصطناعي', button: 'التقاط', onTap: () => _capture(context)),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onTap;
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
