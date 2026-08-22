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
      title: '${json['title'] ?? 'دليل بدون عنوان'}',
      type: '${json['type'] ?? 'نوع غير محدد'}',
      source: '${json['source'] ?? json['sourceType'] ?? 'مصدر غير معروف'}',
      confidence: ((json['confidence'] ?? 0) as num).toDouble(),
      status: '${json['status'] ?? 'DISCOVERED'}',
      date: json['date']?.toString(),
    );
  }
}