import 'package:flutter/material.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
      children: [
        const Text('ملفي', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('ملف الإنجاز الذي يبنيه إنجازي من أدلتك.', style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('نسخة 1448هـ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('86% مكتمل', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility_outlined), label: const Text('معاينة'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('إنشاء PDF'))),
          ])
        ]))),
        const SizedBox(height: 12),
        Card(child: ListTile(leading: const Icon(Icons.link_outlined), title: const Text('الرابط العام'), subtitle: const Text('لم يتم نشر الملف بعد'), trailing: TextButton(onPressed: () {}, child: const Text('نشر')))),
        const SizedBox(height: 12),
        Card(child: ListTile(leading: const Icon(Icons.qr_code_2_outlined), title: const Text('رمز QR'), subtitle: const Text('يتوفر بعد نشر الملف'), trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left)))),
      ],
    );
  }
}
