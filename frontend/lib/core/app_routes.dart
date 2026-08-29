import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/splash_screen/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/map_picker_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/live_scan_screen.dart';
import '../screens/result_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/role-selection';
  static const String mapPicker = '/map-picker';
  static const String home = '/home';
  static const String liveScan = '/live-scan';
  static const String result = '/result';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
      case onboarding:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 800),
        );
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen(), settings: settings);
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen(), settings: settings);
      case mapPicker:
        return MaterialPageRoute(builder: (_) => const MapPickerScreen(), settings: settings);
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen(), settings: settings);
      case liveScan:
        return MaterialPageRoute(builder: (_) => const LiveScanScreen(), settings: settings);
      case result:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageFile: args['imageFile'] as XFile,
            detections: args['detections'] as List<dynamic>,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
