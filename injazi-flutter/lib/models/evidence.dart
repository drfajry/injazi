class Evidence {
  final String id;
  final String title;
  final String type;
  final String source;
  final double confidence;
  final String status;
  final String? date;
  final List<String> linkedIndicatorNames;

  const Evidence({
    required this.id,
    required this.title,
    required this.type,
    required this.source,
    required this.confidence,
    required this.status,
    this.date,
    this.linkedIndicatorNames = const [],
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    final links = json['links'] as List? ?? [];
    final indicatorNames = links
        .map((link) => (link as Map<String, dynamic>)['indicator']?['name'] as String?)
        .whereType<String>()
        .toList();

    return Evidence(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? 'شاهد بدون عنوان'}',
      type: '${json['type'] ?? 'نوع غير محدد'}',
      source: '${json['source'] ?? json['sourceType'] ?? 'مصدر غير معروف'}',
      confidence: ((json['confidence'] ?? 0) as num).toDouble(),
      status: '${json['status'] ?? 'DISCOVERED'}',
      date: json['date']?.toString(),
      linkedIndicatorNames: indicatorNames,
    );
  }
}
