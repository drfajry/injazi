class Evidence {
  final String id;
  final String title;
  final String type;
  final String source;
  final double confidence;
  final String status;
  final String? date;

  const Evidence({
    required this.id,
    required this.title,
    required this.type,
    required this.source,
    required this.confidence,
    required this.status,
    this.date,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? 'دليل دون عنوان'}',
      type: '${json['type'] ?? 'غير مصنف'}',
      source: '${json['source'] ?? json['sourceType'] ?? 'يدوي'}',
      confidence: ((json['confidence'] ?? 0) as num).toDouble(),
      status: '${json['status'] ?? 'DISCOVERED'}',
      date: json['date']?.toString(),
    );
  }
}
