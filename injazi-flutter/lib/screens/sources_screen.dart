import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  Future<void> _uploadFile(BuildContext context) async {
    await FilePicker.platform.pickFiles(allowMultiple: false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… ط§ط®طھظٹط§ط± ط§ظ„ظ…ظ„ظپ. ط³ظ†ط±ط¨ط·ظ‡ ط¨ط§ظ„ظ€API ظ„ط§ط­ظ‚ظ‹ط§.')));
    }
  }

  Future<void> _capture(BuildContext context) async {
    final picker = ImagePicker();
    await picker.pickImage(source: ImageSource.camera);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… ط§ظ„طھظ‚ط§ط· ط§ظ„طµظˆط±ط©. ط³ظ†ط±ظپط¹ظ‡ط§ ظ„ظ„ظ€API ظ„ط§ط­ظ‚ظ‹ط§.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
      children: [
        const Text('ظ…طµط§ط¯ط± ط§ظ„ط£ط¯ظ„ط©', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('ط§ط±ط¨ط· ظ…طµط§ط¯ط±ظƒ ظ…ط±ط© ظˆط§ط­ط¯ط©طŒ ظˆط¥ظ†ط¬ط§ط²ظٹ ظٹط¨ط­ط« ط¹ظ† ط§ظ„ط£ط¯ظ„ط© ظ†ظٹط§ط¨ط©ظ‹ ط¹ظ†ظƒ.', style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 22),
        _SourceCard(icon: Icons.school_outlined, title: 'ظ…ط¯ط±ط³طھظٹ', subtitle: 'ط§ظƒطھط´ط§ظپ ط£ط¹ظ…ط§ظ„ظƒ ط§ظ„طھط¹ظ„ظٹظ…ظٹط© طھظ„ظ‚ط§ط¦ظٹظ‹ط§', button: 'ط±ط¨ط· ظ…ط¯ط±ط³طھظٹ', onTap: () {}),
        const SizedBox(height: 12),
        _SourceCard(icon: Icons.cloud_outlined, title: 'Google Drive', subtitle: 'ط§ظ„ط¨ط­ط« ط¹ظ† ظ…ظ„ظپط§طھظƒ ط§ظ„طھط¹ظ„ظٹظ…ظٹط©', button: 'ط±ط¨ط· Google', onTap: () {}),
        const SizedBox(height: 12),
        _SourceCard(icon: Icons.upload_file_outlined, title: 'ط±ظپط¹ ظٹط¯ظˆظٹ', subtitle: 'ط´ظ‡ط§ط¯ط©طŒ طµظˆط±ط©طŒ ظ…ظ„ظپ ط£ظˆ ط±ط§ط¨ط·', button: 'ط§ط®طھظٹط§ط± ظ…ظ„ظپ', onTap: () => _uploadFile(context)),
        const SizedBox(height: 12),
        _SourceCard(icon: Icons.camera_alt_outlined, title: 'طھطµظˆظٹط± ط´ظ‡ط§ط¯ط©', subtitle: 'ط§ظ„طھظ‚ط§ط· ط´ظ‡ط§ط¯ط© ظˆط³ظٹظ‚ط±ط£ظ‡ط§ ط§ظ„ط°ظƒط§ط، ط§ظ„ط§طµط·ظ†ط§ط¹ظٹ', button: 'ط§ظ„طھظ‚ط§ط·', onTap: () => _capture(context)),
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

