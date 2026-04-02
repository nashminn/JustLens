import 'package:go_router/go_router.dart';
import 'package:justlens/features/home/presentation/home_screen.dart';
import 'package:justlens/features/review/presentation/review_screen.dart';
import 'package:justlens/features/scanner/presentation/scanner_screen.dart';
import 'package:justlens/features/settings/presentation/settings_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const scanner = '/scanner';
  static const review = '/review';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.scanner,
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: AppRoutes.review,
      builder: (context, state) => const ReviewScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
