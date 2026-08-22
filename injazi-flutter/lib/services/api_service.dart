import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/evidence.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const String _tokenKey = 'injazi_access_token';
  static const String _userIdKey = 'injazi_user_id';
  static const String _emailKey = 'injazi_email';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    return _handleAuthResponse(response);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map && decoded['error'] != null) {
        throw Exception(decoded['error'].toString());
      }

      throw Exception('Registration failed');
    }

    return Map<String, dynamic>.from(
      decoded['data'] as Map? ?? <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> _handleAuthResponse(
    http.Response response,
  ) async {
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map && decoded['error'] != null) {
        throw Exception(decoded['error'].toString());
      }
      throw Exception('Authentication failed');
    }

    final data = Map<String, dynamic>.from(
      decoded['data'] as Map? ?? <String, dynamic>{},
    );

    final token = data['accessToken']?.toString();
    final user = Map<String, dynamic>.from(
      data['user'] as Map? ?? <String, dynamic>{},
    );

    if (token == null || token.isEmpty) {
      throw Exception('No access token received');
    }

    await _saveSession(
      token: token,
      userId: user['id']?.toString(),
      email: user['email']?.toString(),
    );

    return data;
  }


  Future<void> forgotPassword({
    required String email,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      throw Exception(
        decoded is Map && decoded['error'] != null
            ? decoded['error'].toString()
            : 'Password reset request failed',
      );
    }
  }
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      }),
    );

    return _handleAuthResponse(response);
  }

  Future<void> resendVerification({
    required String email,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map && decoded['error'] != null) {
        throw Exception(decoded['error'].toString());
      }

      throw Exception('Verification code request failed');
    }
  }
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'password': password,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map && decoded['error'] != null) {
        throw Exception(decoded['error'].toString());
      }

      throw Exception('Password reset failed');
    }
  }
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getAccessToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/me/profile'),
      headers: _authorizedHeaders(token),
    );

    if (response.statusCode == 401) {
      await logout();
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load profile');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded['data'];

    if (data == null) {
      return null;
    }

    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> saveProfile({
    required String name,
    String? schoolName,
    String? stage,
    String? subject,
  }) async {
    final token = await getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication required');
    }

    final response = await _client.put(
      Uri.parse('$baseUrl/me/profile'),
      headers: _authorizedHeaders(token),
      body: jsonEncode({
        'name': name.trim(),
        'schoolName': schoolName?.trim(),
        'stage': stage?.trim(),
        'subject': subject?.trim(),
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map && decoded['error'] != null) {
        throw Exception(decoded['error'].toString());
      }
      throw Exception('Failed to save profile');
    }

    return Map<String, dynamic>.from(
      decoded['data'] as Map,
    );
  }

  Future<void> _saveSession({
    required String token,
    String? userId,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);

    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    }

    if (email != null && email.isNotEmpty) {
      await prefs.setString(_emailKey, email);
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getCurrentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
  }

  Future<List<Evidence>> getEvidence({
    String? status,
  }) async {
    final token = await getAccessToken();

    final uri = Uri.parse('$baseUrl/evidence').replace(
      queryParameters:
          status == null ? null : {'status': status},
    );

    final response = await _client.get(
      uri,
      headers: _authorizedHeaders(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load evidence');
    }

    final data = jsonDecode(response.body);
    final items = data is List
        ? data
        : (data['data'] as List? ?? data['items'] as List? ?? []);

    return items
        .map(
          (e) => Evidence.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<void> approveEvidence(String id) async {
    final token = await getAccessToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/evidence/$id/approve'),
      headers: _authorizedHeaders(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to approve evidence');
    }
  }

  Future<void> rejectEvidence(String id) async {
    final token = await getAccessToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/evidence/$id/reject'),
      headers: _authorizedHeaders(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to reject evidence');
    }
  }

  Future<Map<String, dynamic>> getCoverage() async {
    final token = await getAccessToken();

    final response = await _client.get(
      Uri.parse('$baseUrl/me/coverage'),
      headers: _authorizedHeaders(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load coverage');
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  Future<Map<String, dynamic>> uploadFile({
    required List<int> bytes,
    required String filename,
    String? mimeType,
    String? title,
  }) async {
    final token = await getAccessToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/sources/upload'),
    );

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (title != null && title.trim().isNotEmpty) {
      request.fields['title'] = title.trim();
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ),
    );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(response.body) ?? 'Upload failed';
      throw Exception(message);
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> addUrlEvidence(String url) async {
    final token = await getAccessToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/sources/url'),
      headers: _authorizedHeaders(token),
      body: jsonEncode({'url': url.trim()}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(response.body) ?? 'Failed to add URL';
      throw Exception(message);
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<String> getGoogleAuthUrl() async {
    final token = await getAccessToken();

    final response = await _client.get(
      Uri.parse('$baseUrl/sources/google/auth-url'),
      headers: _authorizedHeaders(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(response.body) ?? 'Failed to start Google connection';
      throw Exception(message);
    }

    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    return data['url'] as String;
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    return null;
  }

  Map<String, String> _authorizedHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  void dispose() {
    _client.close();
  }
}








