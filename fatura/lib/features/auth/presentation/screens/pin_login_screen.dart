/// pin_login_screen.dart — PIN code login screen (4-6 digits)
///
/// Paper Ledger style: ink on cream, forest green PIN dots, stamp red errors.
///
/// Phase 3 updates (US-017, US-018):
/// - Role selector (Owner / POS Clerk / Inventory Manager / Viewer)
/// - Real PIN validation via SHA-256 + salt against users_dao
/// - Role-based navigation to different home screens
/// - Shake animation on error
///
/// Flow logic:
/// - 0 users → redirect to onboarding
/// - 1 user (Owner only) → direct PIN login, no role selector
/// - 2+ users → show dynamic role selector (only roles with active users)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../providers/auth_providers.dart';

/// Role metadata for the selector chips.
class _RoleOption {
  final String value;
  final String label;
  final IconData icon;
  final String homeRoute;

  const _RoleOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.homeRoute,
  });
}

/// All possible roles — used as a lookup table.
const List<_RoleOption> _allRoles = [
  _RoleOption(
    value: 'owner',
    label: AppStrings.roleOwner,
    icon: Icons.admin_panel_settings,
    homeRoute: '/invoices',
  ),
  _RoleOption(
    value: 'pos_clerk',
    label: AppStrings.roleClerk,
    icon: Icons.point_of_sale,
    homeRoute: '/pos',
  ),
  _RoleOption(
    value: 'inventory_manager',
    label: AppStrings.roleInventory,
    icon: Icons.inventory_2,
    homeRoute: '/inventory',
  ),
  _RoleOption(
    value: 'viewer',
    label: AppStrings.roleViewer,
    icon: Icons.bar_chart,
    homeRoute: '/reports',
  ),
];

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen>
    with TickerProviderStateMixin {
  String _pin = '';
  String _selectedRole = 'owner';
  bool _hasError = false;
  bool _isLoading = false;
  bool _initialized = false;

  /// Roles that have at least one active user in the DB.
  List<_RoleOption> _availableRoles = [];

  /// Whether to show the role selector.
  bool _showRoleSelector = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reset();
        }
      });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Fetch active users from DB and determine what UI to show.
  Future<void> _loadUsersAndConfigure() async {
    final usersDao = ref.read(usersDaoProvider);
    final activeUsers = await usersDao.getActiveUsers();

    if (!mounted) return;

    // 0 users → redirect to onboarding
    if (activeUsers.isEmpty) {
      context.go('/');
      return;
    }

    // Determine which roles have active users
    final roleValues = activeUsers.map((u) => u.role).toSet();
    final availableRoles = _allRoles
        .where((r) => roleValues.contains(r.value))
        .toList();

    // 1 user → no role selector, direct login
    // 2+ users → show role selector (dynamic)
    final showSelector = activeUsers.length > 1;

    setState(() {
      _availableRoles = availableRoles;
      _showRoleSelector = showSelector;
      _initialized = true;
      // Default to first available role
      if (availableRoles.isNotEmpty) {
        _selectedRole = availableRoles.first.value;
      }
    });
  }

  void _onDigitPressed(String digit) {
    if (_pin.length < 6 && !_isLoading) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin += digit;
        _hasError = false;
      });
      // Auto-validate at 4, 5, and 6 digits
      if (_pin.length >= 4) {
        _tryLogin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty && !_isLoading) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _hasError = false;
      });
    }
  }

  void _triggerError() {
    HapticFeedback.heavyImpact();
    setState(() {
      _hasError = true;
      _pin = '';
      _isLoading = false;
    });
    _shakeController.forward();
  }

  Future<void> _tryLogin() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final sessionNotifier = ref.read(authSessionProvider.notifier);
    final success = await sessionNotifier.loginWithPin(_pin);

    if (!mounted) return;

    if (success) {
      final session = ref.read(authSessionProvider);
      final role = session.user?.role ?? _selectedRole;

      // Single user → go directly to their role's home
      // Multi-user → go to the selected role's home
      final roleOption = _allRoles.firstWhere(
        (r) => r.value == role,
        orElse: () => _allRoles.first,
      );
      context.go(roleOption.homeRoute);
    } else {
      // If PIN is < 6 digits, don't error yet — let user keep typing
      if (_pin.length < 6) {
        setState(() => _isLoading = false);
        return;
      }
      _triggerError();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch users on first build
    if (!_initialized) {
      _loadUsersAndConfigure();
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.forest,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.xxl),

                // Logo — ledger style
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.forest,
                    border: Border.all(color: AppColors.forestDark, width: 2),
                  ),
                  child: const Icon(
                    Icons.receipt,
                    size: 40,
                    color: AppColors.background,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: AppSizes.sm),

                // Subtitle: show "select your role" only if role selector is visible
                if (_showRoleSelector) ...[
                  Text(
                    AppStrings.selectYourRole,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontMD,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // ── Dynamic Role Selector ──
                  _buildRoleSelector(),
                  const SizedBox(height: AppSizes.xl),
                ] else ...[
                  const SizedBox(height: AppSizes.lg),
                ],

                Text(
                  AppStrings.enterPin,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSizes.xl),

                // PIN dots
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset:
                          Offset(_hasError ? _shakeAnimation.value : 0, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < _pin.length;
                      return AnimatedContainer(
                        duration: AppSizes.durationMicro,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hasError
                              ? AppColors.stampRed
                              : isFilled
                                  ? AppColors.forest
                                  : Colors.transparent,
                          border: Border.all(
                            color: _hasError
                                ? AppColors.stampRed
                                : AppColors.inkMuted,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Error / loading area
                SizedBox(
                  height: AppSizes.xl,
                  child: AnimatedSwitcher(
                    duration: AppSizes.durationShort,
                    child: _hasError
                        ? Text(
                            AppStrings.wrongPin,
                            key: const ValueKey('error'),
                            style: const TextStyle(
                              color: AppColors.stampRed,
                              fontFamily: 'Cairo',
                              fontSize: AppSizes.fontSM,
                            ),
                          )
                        : _isLoading
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.forest,
                                ),
                              )
                            : const SizedBox(key: ValueKey('empty')),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Number pad
                RepaintBoundary(child: _buildNumPad()),
                const SizedBox(height: AppSizes.lg),

                TextButton(
                  onPressed: _isLoading ? null : () => context.go('/'),
                  child: const Text(
                    AppStrings.skip,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Dynamic Role Selector ──

  Widget _buildRoleSelector() {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      alignment: WrapAlignment.center,
      children: _availableRoles.map((role) {
        final isSelected = _selectedRole == role.value;
        return GestureDetector(
          onTap: () => setState(() => _selectedRole = role.value),
          child: AnimatedContainer(
            duration: AppSizes.durationShort,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMD,
              vertical: AppSizes.paddingSM,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.forest : AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              border: Border.all(
                color: isSelected
                    ? AppColors.forestDark
                    : AppColors.ledgerBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  role.icon,
                  size: 18,
                  color:
                      isSelected ? AppColors.background : AppColors.inkLight,
                ),
                const SizedBox(width: 6),
                Text(
                  role.label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? AppColors.background : AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Number Pad ──

  Widget _buildNumPad() {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['⌫', '0', '✓'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key == '⌫') {
                  return _NumKey(
                    label: key,
                    onTap: _onDeletePressed,
                    isAction: true,
                  );
                }
                if (key == '✓') {
                  return _NumKey(
                    label: key,
                    onTap: () {
                      if (_pin.length >= 4 && !_isLoading) _tryLogin();
                    },
                    isAction: true,
                    actionColor: AppColors.forest,
                  );
                }
                return _NumKey(
                  label: key,
                  onTap: () => _onDigitPressed(key),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

/// Single number-pad key — flat bordered circle, Paper Ledger style.
class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;
  final Color? actionColor;

  const _NumKey({
    required this.label,
    required this.onTap,
    this.isAction = false,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = actionColor ?? AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAction ? actionColor : AppColors.card,
          border: Border.all(
            color: isAction ? color : AppColors.ledgerBorder,
            width: 1.5,
          ),
        ),
        child: Center(
          child: label == '⌫'
              ? Icon(Icons.backspace_outlined, size: 24, color: color)
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontXL,
                    fontWeight: FontWeight.w600,
                    color: isAction ? AppColors.background : AppColors.ink,
                  ),
                ),
        ),
      ),
    );
  }
}