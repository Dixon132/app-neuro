import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.loginEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.registerEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> uploadEEGBytes(
    Uint8List fileBytes,
    String fileName,
  ) async {
    final token = await _storage.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.uploadEndpoint}'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Usar bytes en lugar de path (compatible con web)
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Intentar extraer el mensaje de detalle del backend
      String errorDetail;
      try {
        final errorBody = jsonDecode(response.body);
        errorDetail = errorBody['detail'] ?? response.body;
      } catch (_) {
        errorDetail = response.body;
      }
      throw Exception('Upload failed (${response.statusCode}): $errorDetail');
    }
  }

  Future<List<dynamic>> getAnalysisList() async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.analysisListEndpoint}',
      ),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load analyses');
    }
  }

  Future<Map<String, dynamic>> getAnalysisDetail(int id) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/analysis/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load analysis detail');
    }
  }

  Future<Uint8List> downloadReport(int analysisId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/analysis/$analysisId/report'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    // Extraer mensaje de detalle del backend
    String errorDetail;
    try {
      final errorBody = jsonDecode(response.body);
      errorDetail = errorBody['detail'] ?? response.body;
    } catch (_) {
      errorDetail = response.body;
    }
    throw Exception('Download failed (${response.statusCode}): $errorDetail');
  }
}
