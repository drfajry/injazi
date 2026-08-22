import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Fetches all criteria/indicators and shows a picker dialog. Returns the
/// chosen indicator id, or null if the person cancelled or the fetch failed.
/// Shared between the post-upload flow (Sources tab) and the dashboard
/// evidence list, so both places offer the same manual indicator-assignment
/// experience without duplicating the fetch/dialog logic.
Future<String?> pickIndicator(BuildContext context, ApiService api) async {
  List<Map<String, String>> allIndicators;

  try {
    final preview = await api.getPortfolioPreview();
    final sections = List<Map<String, dynamic>>.from(
      (preview['sections'] as List).map((s) => Map<String, dynamic>.from(s)),
    );

    allIndicators = [];
    for (final section in sections) {
      for (final indicator in (section['indicators'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(indicator);
        allIndicators.add({
          'id': map['id'] as String,
          'name': '${section['name']} — ${map['name']}',
        });
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تحميل قائمة المؤشرات: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
    return null;
  }

  if (!context.mounted) return null;

  final searchController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: StatefulBuilder(
        builder: (context, setState) {
          final query = searchController.text.trim();
          final filtered = query.isEmpty
              ? allIndicators
              : allIndicators.where((i) => (i['name'] ?? '').contains(query)).toList();

          return AlertDialog(
            title: const Text('اختر المؤشر المناسب'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'ابحث عن مؤشر...',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final indicator = filtered[index];
                        return ListTile(
                          dense: true,
                          title: Text(indicator['name'] ?? '', style: const TextStyle(fontSize: 13)),
                          onTap: () => Navigator.pop(context, indicator['id']),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ],
          );
        },
      ),
    ),
  );
}
