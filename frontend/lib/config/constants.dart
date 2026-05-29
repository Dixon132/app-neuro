class AppConstants {
  static const String appName = 'EEG Analysis';
  static const String apiBaseUrl = 'http://localhost:8000/api';
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String uploadEndpoint = '/analysis/upload';
  static const String analysisListEndpoint = '/analysis/list';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // File Types
  static const List<String> allowedExtensions = ['edf', 'csv'];
  static const int maxFileSizeMB = 100;
}
