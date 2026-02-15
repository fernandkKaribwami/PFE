import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String apiBaseUrl = 'https://api.example.com';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await getHeaders();
    return http.get(Uri.parse('$apiBaseUrl$endpoint'), headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return http.post(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return http.put(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await getHeaders();
    return http.delete(Uri.parse('$apiBaseUrl$endpoint'), headers: headers);
  }

  Future<http.StreamedResponse> postMultipart(
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    String filePath,
  ) async {
    final headers = await getHeaders();
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBaseUrl$endpoint'),
    );
    req.headers.addAll(headers);

    fields.forEach((key, value) {
      req.fields[key] = value;
    });

    if (filePath.isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath(fileFieldName, filePath));
    }

    return req.send();
  }
}
