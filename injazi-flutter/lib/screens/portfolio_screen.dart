import 'package:flutter/material.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
      children: [
        const Text('ملف الإنجاز', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('راجع ملفك المهني وشاركه أو صدّره بصيغة PDF متى شئت.', style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('العام الدراسي 1448هـ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('نسبة الاكتمال 86%', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility_outlined), label: const Text('معاينة'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('تصدير PDF'))),
          ])
        ]))),
        const SizedBox(height: 12),
        Card(child: ListTile(leading: const Icon(Icons.link_outlined), title: const Text('الرابط العام'), subtitle: const Text('شارك ملفك مع أي جهة عبر رابط مباشر'), trailing: TextButton(onPressed: () {}, child: const Text('نسخ')))),
        const SizedBox(height: 12),
        Card(child: ListTile(leading: const Icon(Icons.qr_code_2_outlined), title: const Text('رمز QR'), subtitle: const Text('امسح الرمز للوصول السريع لملفك'), trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left)))),
      ],
    );
  }
}