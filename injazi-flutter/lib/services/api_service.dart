import 'dart:convert';

import 'package:http/http.dart' as http;
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


return _handleAuthResponse(response);


}

Future<Map<String, dynamic>> _handleAuthResponse(
http.Response response,
) async {
final decoded = _decodeObject(response.body);


if (response.statusCode < 200 || response.statusCode >= 300) {
  throw Exception(
    decoded['error']?.toString() ?? 'ط­ط¯ط« ط®ط·ط£ ط؛ظٹط± ظ…طھظˆظ‚ط¹',
  );
}

final data = Map<String, dynamic>.from(
  decoded['data'] as Map? ?? <String, dynamic>{},
);

final token = data['accessToken']?.toString();
final user = Map<String, dynamic>.from(
  data['user'] as Map? ?? <String, dynamic>{},
);

if (token == null || token.isEmpty) {
  throw Exception('ظ„ظ… ظٹطھظ… ط§ط³طھظ„ط§ظ… ط¬ظ„ط³ط© ط§ظ„ط¯ط®ظˆظ„');
}

await _saveSession(
  token: token,
  userId: user['id']?.toString(),
  email: user['email']?.toString(),
);

return data;


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
  queryParameters: status == null
      ? null
      : {'status': status},
);

final response = await _client.get(
  uri,
  headers: _authorizedHeaders(token),
);

if (response.statusCode < 200 || response.statusCode >= 300) {
  throw Exception('طھط¹ط°ط± ط¬ظ„ط¨ ط§ظ„ط£ط¯ظ„ط© (${response.statusCode})');
}

final data = _decodeObjectOrList(response.body);
final items = data is List
    ? data
    : (data['items'] as List? ?? []);

return items
    .map(
      (e) => Evidence.fromJson(
        Map<String, dynamic>.from(e),
      ),
    )
    .toList();


}

Future<Map<String, dynamic>> getCoverage() async {
final token = await getAccessToken();


final response = await _client.get(
  Uri.parse('$baseUrl/me/coverage'),
  headers: _authorizedHeaders(token),
);

if (response.statusCode < 200 || response.statusCode >= 300) {
  throw Exception(
    'طھط¹ط°ط± ط¬ظ„ط¨ ط§ظ„طھط؛ط·ظٹط© (${response.statusCode})',
  );
}

return _decodeObject(response.body);


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

Map<String, dynamic> _decodeObject(String body) {
final decoded = jsonDecode(body);


if (decoded is Map<String, dynamic>) {
  return decoded;
}

return <String, dynamic>{};


}

dynamic _decodeObjectOrList(String body) {
return jsonDecode(body);
}

void dispose() {
_client.close();
}
}
