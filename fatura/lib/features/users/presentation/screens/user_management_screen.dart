/// user_management_screen.dart — User Management (US-017, US-018, US-019)
///
/// Owner-only screen for managing employees:
/// - List users as Paper Ledger cards
/// - Add / edit / deactivate / delete users
/// - Role selection + permission checkboxes
/// - PIN entry with confirm
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database.dart' as db;
import '../../../auth/providers/auth_providers.dart';
import 'add_edit_user_dialog.dart';

// ─── Providers ───

/// Reactive list of all users.
final allUsersProvider = FutureProvider<List<db.User>>((ref) async {
  final usersDao = ref.watch(usersDaoProvider);
  return usersDao.getAllUsers();
});

/// Role metadata.
class RoleMeta {
  final String value;
  final String label;
  final IconData icon;
  final List<String> defaultPerms;
  const RoleMeta(this.value, this.label, this.icon, this.defaultPerms);
}

const roleMeta = <String, RoleMeta>{
  'owner': RoleMeta('owner', AppStrings.roleOwner,
      Icons.admin_panel_settings, ['*']),
  'pos_clerk': RoleMeta('pos_clerk', AppStrings.roleClerk,
      Icons.point_of_sale, ['pos', 'invoices']),
  'inventory_manager': RoleMeta('inventory_manager', AppStrings.roleInventory,
      Icons.inventory_2, ['inventory']),
  'viewer': RoleMeta('viewer', AppStrings.roleViewer,
      Icons.bar_chart, ['reports']),
};

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Owner-only guard
    final session = ref.watch(authSessionProvider);
    if (!session.isOwner) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('إدارة الموظفين')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.stampRed),
              SizedBox(height: AppSizes.md),
              Text(
                AppStrings.ownerOnly,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontLG,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الموظفين'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppStrings.activityLog,
            onPressed: () => context.go('/activity-log'),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.forest),
        ),
        error: (e, _) => Center(
          child: Text('خطأ: $e',
              style: const TextStyle(fontFamily: 'Cairo')),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: AppColors.inkMuted),
                  SizedBox(height: AppSizes.md),
                  Text(
                    AppStrings.noUsers,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontLG,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final role = roleMeta[user.role];
              final isActive = user.isActive;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  child: Row(
                    children: [
                      // Avatar circle with initial
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.forest
                              : AppColors.inkMuted,
                          border: Border.all(
                            color: isActive
                                ? AppColors.forestDark
                                : AppColors.ledgerBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      // Name + role + status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: AppSizes.fontMD,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (role != null) ...[
                                  Icon(role.icon,
                                      size: 14, color: AppColors.inkMuted),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  role?.label ?? user.role,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: AppSizes.fontSM,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.forest.withValues(alpha: 0.15)
                                        : AppColors.stampRed.withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.radiusSM),
                                    border: Border.all(
                                      color: isActive
                                          ? AppColors.forest
                                          : AppColors.stampRed,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    isActive
                                        ? AppStrings.userActive
                                        : AppStrings.userInactive,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? AppColors.forest
                                          : AppColors.stampRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Actions menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: AppColors.inkLight),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(AppStrings.edit),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(children: [
                              Icon(
                                isActive
                                    ? Icons.pause_circle_outlined
                                    : Icons.play_circle_outlined,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(isActive
                                  ? AppStrings.deactivateUser
                                  : AppStrings.activateUser),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 20, color: AppColors.stampRed),
                              SizedBox(width: 8),
                              Text(AppStrings.delete,
                                  style:
                                      TextStyle(color: AppColors.stampRed)),
                            ]),
                          ),
                        ],
                        onSelected: (action) async {
                          final usersDao = ref.read(usersDaoProvider);
                          switch (action) {
                            case 'edit':
                              showDialog(
                                context: context,
                                builder: (_) => AddEditUserDialog(
                                  existing: user,
                                ),
                              ).then((result) {
                                if (result == true) {
                                  ref.invalidate(allUsersProvider);
                                }
                              });
                              break;
                            case 'toggle':
                              await usersDao.setActive(
                                  user.id, !user.isActive);
                              ref.invalidate(allUsersProvider);
                              break;
                            case 'delete':
                              if (context.mounted) {
                                _confirmDelete(context, ref, user);
                              }
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddEditUserDialog(),
          ).then((result) {
            if (result == true) {
              ref.invalidate(allUsersProvider);
            }
          });
        },
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// ─── Confirm Delete ───

void _confirmDelete(
    BuildContext context, WidgetRef ref, db.User user) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(AppStrings.deleteUser,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      content: Text(AppStrings.confirmDeleteUser,
          style: const TextStyle(fontFamily: 'Cairo')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.stampRed,
            foregroundColor: AppColors.background,
          ),
          onPressed: () async {
            final usersDao = ref.read(usersDaoProvider);
            await usersDao.deleteUser(user.id);
            if (ctx.mounted) Navigator.of(ctx).pop();
            ref.invalidate(allUsersProvider);
          },
          child: const Text(AppStrings.delete),
        ),
      ],
    ),
  );
}