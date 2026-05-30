import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/analysis/eeg_upload_screen.dart';
import '../screens/analysis/analysis_detail_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

class AppRoutes {
  // home ('/') is AppStartup in main.dart
  // Onboarding has its own named route
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String upload = '/upload';
  static const String analysisDetail = '/analysis-detail';
  static const String adminLogin = '/admin-login';
  static const String adminDashboard = '/admin-dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(
            builder: (_) => const OnboardingScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(
            builder: (_) => const RegisterScreen());

      case dashboard:
        return MaterialPageRoute(
            builder: (_) => const DashboardScreen());

      case upload:
        return MaterialPageRoute(
            builder: (_) => const EEGUploadScreen());

      case analysisDetail:
        final analysisId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) =>
              AnalysisDetailScreen(analysisId: analysisId),
        );

      case adminLogin:
        return MaterialPageRoute(
            builder: (_) => const AdminLoginScreen());

      case adminDashboard:
        return MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen());

      default:
        // Unknown route — go to login
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
