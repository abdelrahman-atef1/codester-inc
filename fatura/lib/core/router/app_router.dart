/// app_router.dart — GoRouter configuration for Fatura
///
/// Phase 3 updates:
/// - Route guards based on user role/permissions
/// - Routes for user management + activity log
/// - Redirect logic: unauthenticated → /login, unauthorized → /invoices
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_sizes.dart';
import '../../features/auth/presentation/screens/pin_login_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/invoices/presentation/screens/invoice_list_screen.dart';
import '../../features/invoices/presentation/screens/invoice_detail_screen.dart';
import '../../features/reports/presentation/screens/daily_report_screen.dart';
import '../../features/inventory/presentation/screens/product_list_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/users/presentation/screens/user_management_screen.dart';
import '../../features/users/presentation/screens/activity_log_screen.dart';
import '../../features/users/providers/permission_providers.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/feedback/presentation/screens/feedback_list_screen.dart';
import '../../features/sync/presentation/screens/sync_screen.dart';
import '../../features/sync/presentation/screens/qr_setup_screen.dart';
import '../theme/app_layout.dart';
import '../../../features/inventory/providers/inventory_providers.dart'
    show appDatabaseProvider;

/// Custom slide transition (RTL-aware)
CustomTransitionPage<T> _slideTransition<T>({
  required Widget child,
  Duration duration = AppSizes.transitionSlide,
  Curve curve = Curves.easeInOut,
}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final isRTL = Directionality.of(context) == TextDirection.rtl;
      final offsetX = isRTL ? -1.0 : 1.0;
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(offsetX, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve)),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

/// Fade + scale transition (onboarding → home)
CustomTransitionPage<T> _fadeScaleTransition<T>({
  required Widget child,
  Duration duration = AppSizes.transitionFade,
  Curve curve = Curves.easeOut,
}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: curve),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Scale + fade transition (POS entry — Hero-like expand)
CustomTransitionPage<T> _scaleFadeTransition<T>({
  required Widget child,
  Duration duration = AppSizes.transitionScale,
  Curve curve = Curves.easeOutBack,
}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: AppSizes.transitionSlide,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

/// Shell route for main app screens (with bottom nav / sidebar)
CustomTransitionPage<T> _tabTransition<T>({
  required Widget child,
  Duration duration = AppSizes.transitionTab,
}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Permission required for each route.
const Map<String, String> _routePermissions = {
  '/pos': Permissions.pos,
  '/invoices': Permissions.invoices,
  '/invoices/:id': Permissions.invoices,
  '/inventory': Permissions.inventory,
  '/reports': Permissions.reports,
  '/reports/daily': Permissions.reports,
  '/settings': Permissions.settings,
  '/users': Permissions.users,
  '/activity-log': Permissions.activityLog,
  '/feedback': Permissions.settings,
  '/feedback/list': Permissions.users,
  '/sync': Permissions.settings,
  '/sync/qr': Permissions.settings,
};

/// Async provider: checks whether a store exists in the DB.
/// Used by the router redirect to skip onboarding on subsequent launches.
final hasStoreProvider = FutureProvider<bool>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final store = await database.storesDao.getFirstStore();
  return store != null;
});

/// GoRouter with a redirect guard for auth + onboarding + permissions.
GoRouter createRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final path = state.uri.path;
      final hasStore = ref.read(hasStoreProvider).maybeWhen(
        data: (v) => v,
        orElse: () => null,
      );

      // While checking DB, stay on splash (don't redirect yet).
      if (hasStore == null) return null;

      // Root → onboarding or login depending on DB state.
      if (path == '/') {
        return hasStore ? '/login' : null; // null = stay on onboarding
      }

      // Login is always accessible.
      if (path == '/login') return null;

      // Not logged in → send to login.
      if (!session.isLoggedIn) return '/login';

      // Check route-specific permission.
      final requiredPerm = _routePermissions[path];
      if (requiredPerm != null) {
        final hasPermission = ref.read(permissionProvider(requiredPerm));
        if (!hasPermission) {
          // Redirect to invoices as a safe default.
          return '/invoices';
        }
      }

      return null;
    },
    routes: [
      // Splash / Onboarding
      GoRoute(
        path: '/',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
        pageBuilder: (context, state) =>
            _fadeScaleTransition(child: const OnboardingScreen()),
      ),

      // PIN Login
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const PinLoginScreen(),
        pageBuilder: (context, state) =>
            _fadeScaleTransition(child: const PinLoginScreen()),
      ),

      // ─── Main shell with bottom nav (invoices, inventory, reports, settings) ───
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          // Invoices list (default home)
          GoRoute(
            path: '/invoices',
            name: 'invoices',
            builder: (context, state) => const InvoiceListScreen(),
            pageBuilder: (context, state) =>
                _tabTransition(child: const InvoiceListScreen()),
          ),

          // Inventory
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            builder: (context, state) => const ProductListScreen(),
            pageBuilder: (context, state) =>
                _tabTransition(child: const ProductListScreen()),
          ),

          // Reports hub
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
            pageBuilder: (context, state) =>
                _tabTransition(child: const ReportsScreen()),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            pageBuilder: (context, state) =>
                _tabTransition(child: const SettingsScreen()),
          ),
        ],
      ),

      // ─── Routes outside the shell (full-screen, no bottom nav) ───

      // Invoice detail
      GoRoute(
        path: '/invoices/:id',
        name: 'invoice_detail',
        builder: (context, state) => InvoiceDetailScreen(
          invoiceId: int.parse(state.pathParameters['id']!),
        ),
        pageBuilder: (context, state) =>
            _slideTransition(child: InvoiceDetailScreen(
              invoiceId: int.parse(state.pathParameters['id']!),
            )),
      ),

      // Daily report
      GoRoute(
        path: '/reports/daily',
        name: 'daily_report',
        builder: (context, state) => const DailyReportScreen(),
        pageBuilder: (context, state) =>
            _slideTransition(child: const DailyReportScreen()),
      ),

      // POS — special scale+fade transition (Hero-like expand from button)
      GoRoute(
        path: '/pos',
        name: 'pos',
        builder: (context, state) => const PosScreen(),
        pageBuilder: (context, state) =>
            _scaleFadeTransition(child: const PosScreen()),
      ),

      // User management (Owner only)
      GoRoute(
        path: '/users',
        name: 'users',
        builder: (context, state) => const UserManagementScreen(),
        pageBuilder: (context, state) =>
            _slideTransition(child: const UserManagementScreen()),
      ),

      // Activity log (Owner only)
      GoRoute(
        path: '/activity-log',
        name: 'activity_log',
        builder: (context, state) => const ActivityLogScreen(),
        pageBuilder: (context, state) =>
            _slideTransition(child: const ActivityLogScreen()),
      ),

      // Feedback — submit new feedback (all users)
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        builder: (context, state) => const FeedbackScreen(),
        pageBuilder: (context, state) =>
            _slideTransition(child: const FeedbackScreen()),
      ),

      // Feedback list (Owner only)
      GoRoute(
        path: '/feedback/list',
        name: 'feedback_list',
        builder: (context, state) => const FeedbackListScreen(),
        pageBuilder: (context, state) =>
            _slideTransition(child: const FeedbackListScreen()),
      ),

      // ─── Sync Module Routes ───

      // Sync main screen (Owner + Employee)
      GoRoute(
        path: '/sync',
        name: 'sync',
        builder: (context, state) => const SyncScreen(),
        pageBuilder: (context, state) =>
            _slideTransition(child: const SyncScreen()),
      ),

      // QR setup screen (Owner generate / Employee scan)
      GoRoute(
        path: '/sync/qr',
        name: 'sync_qr',
        builder: (context, state) => const QrSetupScreen(),
        pageBuilder: (context, state) =>
            _slideTransition(child: const QrSetupScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}

/// Riverpod provider for the router.
final routerProvider = Provider<GoRouter>((ref) {
  return createRouter(ref);
});