import 'package:flutter/material.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
      children: [
        const Text('ظ…ظ„ظپظٹ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('ظ…ظ„ظپ ط§ظ„ط¥ظ†ط¬ط§ط² ط§ظ„ط°ظٹ ظٹط¨ظ†ظٹظ‡ ط¥ظ†ط¬ط§ط²ظٹ ظ…ظ† ط£ط¯ظ„طھظƒ.', style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ظ†ط³ط®ط© 1448ظ‡ظ€', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('86% ظ…ظƒطھظ…ظ„', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility_outlined), label: const Text('ظ…ط¹ط§ظٹظ†ط©'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('ط¥ظ†ط´ط§ط، PDF'))),
          ])
        ]))),
        const SizedBox(height: 12),
        Card(child: ListTile(leading: const Icon(Icons.link_outlined), title: const Text('ط§ظ„ط±ط§ط¨ط· ط§ظ„ط¹ط§ظ…'), subtitle: const Text('ظ„ظ… ظٹطھظ… ظ†ط´ط± ط§ظ„ظ…ظ„ظپ ط¨ط¹ط¯'), trailing: TextButton(onPressed: () {}, child: const Text('ظ†ط´ط±')))),
        const SizedBox(height: 12),
        Card(child: ListTile(leading: const Icon(Icons.qr_code_2_outlined), title: const Text('ط±ظ…ط² QR'), subtitle: const Text('ظٹطھظˆظپط± ط¨ط¹ط¯ ظ†ط´ط± ط§ظ„ظ…ظ„ظپ'), trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left)))),
      ],
    );
  }
}

