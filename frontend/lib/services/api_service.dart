import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';

class MultipartAttachment {
  final String fileName;
  final String? path;
  final Uint8List? bytes;

  const MultipartAttachment({required this.fileName, this.path, this.bytes});

  bool get hasData =>
      (bytes != null && bytes!.isNotEmpty) ||
      (path != null && path!.isNotEmpty);
}

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
    return http.get(
      Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
      headers: headers,
    );
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return http.post(
      Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return http.put(
      Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await getHeaders();
    return http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
      headers: headers,
    );
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await getHeaders();
    return http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.StreamedResponse> postMultipart(
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    String filePath, {
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final attachments = <MultipartAttachment>[
      if ((fileBytes != null && fileName != null && fileName.isNotEmpty) ||
          filePath.isNotEmpty)
        MultipartAttachment(
          fileName: fileName?.isNotEmpty == true
              ? fileName!
              : filePath.split(RegExp(r'[\\/]')).last,
          bytes: fileBytes,
          path: filePath.isNotEmpty ? filePath : null,
        ),
    ];

    return _sendMultipart(
      method: 'POST',
      endpoint: endpoint,
      fields: fields,
      fileFieldName: fileFieldName,
      files: attachments,
    );
  }

  Future<http.StreamedResponse> putMultipart(
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    String filePath, {
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final attachments = <MultipartAttachment>[
      if ((fileBytes != null && fileName != null && fileName.isNotEmpty) ||
          filePath.isNotEmpty)
        MultipartAttachment(
          fileName: fileName?.isNotEmpty == true
              ? fileName!
              : filePath.split(RegExp(r'[\\/]')).last,
          bytes: fileBytes,
          path: filePath.isNotEmpty ? filePath : null,
        ),
    ];

    return _sendMultipart(
      method: 'PUT',
      endpoint: endpoint,
      fields: fields,
      fileFieldName: fileFieldName,
      files: attachments,
    );
  }

  Future<http.StreamedResponse> postMultipartFiles(
    String endpoint,
    Map<String, String> fields,
    String fileFieldName,
    List<MultipartAttachment> files,
  ) async {
    return _sendMultipart(
      method: 'POST',
      endpoint: endpoint,
      fields: fields,
      fileFieldName: fileFieldName,
      files: files,
    );
  }

  Future<http.StreamedResponse> _sendMultipart({
    required String method,
    required String endpoint,
    required Map<String, String> fields,
    required String fileFieldName,
    required List<MultipartAttachment> files,
  }) async {
    final headers = await getHeaders();
    final req = http.MultipartRequest(
      method,
      Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
    );
    headers.remove('Content-Type');
    req.headers.addAll(headers);

    fields.forEach((key, value) {
      req.fields[key] = value;
    });

    for (final file in files.where((candidate) => candidate.hasData)) {
      if (file.path != null && file.path!.isNotEmpty) {
        req.files.add(
          await http.MultipartFile.fromPath(
            fileFieldName,
            file.path!,
            filename: file.fileName,
          ),
        );
      } else if (file.bytes != null && file.bytes!.isNotEmpty) {
        req.files.add(
          http.MultipartFile.fromBytes(
            fileFieldName,
            file.bytes!,
            filename: file.fileName,
          ),
        );
      }
    }

    return req.send();
  }
}
