/// app_layout.dart — Responsive layout: Mobile bottom nav / Tablet+Web sidebar
///
/// Paper Ledger style: cream surfaces, ink borders, forest green active,
/// stamp red POS button (like a merchant's rubber stamp).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

/// Navigation destinations
class NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// All nav items (POS is center special button, not in this list)
final List<NavDestination> navDestinations = [
  const NavDestination(
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    label: AppStrings.navInvoices,
    route: '/invoices',
  ),
  const NavDestination(
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
    label: AppStrings.navInventory,
    route: '/inventory',
  ),
  // POS is the center button — not rendered as a normal nav item
  const NavDestination(
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart,
    label: AppStrings.navReports,
    route: '/reports',
  ),
  const NavDestination(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    label: AppStrings.navSettings,
    route: '/settings',
  ),
];

/// Responsive layout state: which screen is currently shown
final currentRouteProvider = StateProvider<String>((ref) => '/invoices');

/// Responsive layout widget
class AppScaffold extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= AppSizes.tabletBreakpoint) {
      return _TabletLayout(currentRoute: currentRoute, child: child);
    }
    return _MobileLayout(currentRoute: currentRoute, child: child);
  }
}

/// ===== Mobile: Bottom Navigation with center POS button =====
class _MobileLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const _MobileLayout({required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavWithPos(
        currentRoute: currentRoute,
      ),
    );
  }
}

/// Custom bottom nav bar with center POS button (stamp red circle)
class _BottomNavWithPos extends StatelessWidget {
  final String currentRoute;

  const _BottomNavWithPos({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.bottomNavHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Left: Invoices + Inventory
          _NavIcon(
            destination: navDestinations[0],
            isActive: currentRoute == navDestinations[0].route,
          ),
          _NavIcon(
            destination: navDestinations[1],
            isActive: currentRoute == navDestinations[1].route,
          ),
          // Center: POS Button (stamp red circle)
          const _PosButton(),
          // Right: Reports + Settings
          _NavIcon(
            destination: navDestinations[2],
            isActive: currentRoute == navDestinations[2].route,
          ),
          _NavIcon(
            destination: navDestinations[3],
            isActive: currentRoute == navDestinations[3].route,
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final NavDestination destination;
  final bool isActive;

  const _NavIcon({required this.destination, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(destination.route),
      child: AnimatedContainer(
        duration: AppSizes.durationShort,
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? destination.activeIcon : destination.icon,
              size: AppSizes.bottomNavItemSize,
              color: isActive ? AppColors.forest : AppColors.inkMuted,
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.forest : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular POS button — stamp red with subtle border (like a rubber stamp)
class _PosButton extends StatelessWidget {
  const _PosButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pos'),
      child: Container(
        width: AppSizes.posButtonSize,
        height: AppSizes.posButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.stampRed,
          border: Border.all(color: AppColors.stampRedDark, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.posButtonGlow,
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.point_of_sale,
          color: AppColors.background,
          size: AppSizes.posButtonIconSize,
        ),
      ),
    );
  }
}

/// ===== Tablet/Web: Sidebar Navigation =====
class _TabletLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const _TabletLayout({required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: AppSizes.sidebarWidth,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(color: AppColors.ledgerBorder, width: 1.5),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppSizes.lg),
                // Logo
                Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.forest,
                          border: Border.all(color: AppColors.forestDark, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.receipt,
                          color: AppColors.background,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            AppStrings.appTagline,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.ledgerLine),
                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm, vertical: AppSizes.sm),
                    children: [
                      _SidebarItem(
                        destination: navDestinations[0],
                        isActive: currentRoute == navDestinations[0].route,
                      ),
                      _SidebarItem(
                        destination: navDestinations[1],
                        isActive: currentRoute == navDestinations[1].route,
                      ),
                      // POS special item
                      const _SidebarPosItem(),
                      _SidebarItem(
                        destination: navDestinations[2],
                        isActive: currentRoute == navDestinations[2].route,
                      ),
                      _SidebarItem(
                        destination: navDestinations[3],
                        isActive: currentRoute == navDestinations[3].route,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Main content
        Expanded(child: child),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final NavDestination destination;
  final bool isActive;

  const _SidebarItem({required this.destination, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(
          isActive ? destination.activeIcon : destination.icon,
          color: isActive ? AppColors.forest : AppColors.inkMuted,
        ),
        title: Text(
          destination.label,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: isActive ? AppColors.forest : AppColors.inkLight,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          side: isActive
              ? const BorderSide(color: AppColors.ledgerBorder, width: 1)
              : BorderSide.none,
        ),
        tileColor: isActive
            ? AppColors.forest.withValues(alpha: 0.08)
            : Colors.transparent,
        onTap: () => context.go(destination.route),
      ),
    );
  }
}

class _SidebarPosItem extends StatelessWidget {
  const _SidebarPosItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          onTap: () => context.push('/pos'),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.stampRed,
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              border: Border.all(color: AppColors.stampRedDark, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.point_of_sale, color: AppColors.background),
                SizedBox(width: 12),
                Text(
                  AppStrings.navPos,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.background,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}