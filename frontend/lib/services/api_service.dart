import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Login fallido');
    }
  }

  Future<Map<String, dynamic>> adminLogin(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Acceso denegado');
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
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Registro fallido');
    }
  }

  Future<Map<String, dynamic>> uploadEEGBytes(
      Uint8List fileBytes, String fileName) async {
    final token = await _storage.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.uploadEndpoint}'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
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
          '${AppConstants.apiBaseUrl}${AppConstants.analysisListEndpoint}'),
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

    String errorDetail;
    try {
      final errorBody = jsonDecode(response.body);
      errorDetail = errorBody['detail'] ?? response.body;
    } catch (_) {
      errorDetail = response.body;
    }
    throw Exception(
        'Download failed (${response.statusCode}): $errorDetail');
  }

  // ─── Admin endpoints ───────────────────────────────────────────────
  Future<List<dynamic>> getAdminPatients() async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/admin/patients'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar pacientes');
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/admin/stats'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar estadísticas');
  }

  Future<Map<String, dynamic>> createAdmin(
      Map<String, dynamic> adminData) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/admin/create-admin'),
      headers: await _getHeaders(),
      body: jsonEncode(adminData),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final err = jsonDecode(response.body);
    throw Exception(err['detail'] ?? 'Error al crear admin');
  }

  Future<List<dynamic>> getAdmins() async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/admin/admins'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar administradores');
  }

  Future<void> deleteAdmin(int adminId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}/admin/admins/$adminId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Error al eliminar administrador');
    }
  }

  Future<void> deleteAnalysis(int analysisId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}/analysis/$analysisId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Error al eliminar análisis');
    }
  }

  Future<List<dynamic>> getAdminAllAnalyses(int patientId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/admin/patients/$patientId/analyses'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar análisis del paciente');
  }
}
