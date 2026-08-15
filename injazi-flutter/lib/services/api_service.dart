import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/evidence.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  Future<List<Evidence>> getEvidence({String? status}) async {
    final uri = Uri.parse('$baseUrl/me/evidence').replace(
      queryParameters: status == null ? null : {'status': status},
    );
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('تعذر جلب الأدلة (${response.statusCode})');
    }
    final data = jsonDecode(response.body);
    final items = data is List ? data : (data['items'] as List? ?? []);
    return items.map((e) => Evidence.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Map<String, dynamic>> getCoverage() async {
    final response = await _client.get(Uri.parse('$baseUrl/me/coverage'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('تعذر جلب التغطية (${response.statusCode})');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }
}
