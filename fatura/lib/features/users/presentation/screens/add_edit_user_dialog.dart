/// add_edit_user_dialog.dart — Dialog for adding/editing a user
///
/// Paper Ledger style: underline inputs, flat bordered buttons, Cairo font.
library;

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database.dart' as db;
import '../../../../core/utils/pin_hasher.dart';
import '../../../auth/providers/auth_providers.dart'
    show usersDaoProvider, authActivityLogDaoProvider;
import '../../providers/permission_providers.dart';
import 'user_management_screen.dart' show roleMeta;

class AddEditUserDialog extends ConsumerStatefulWidget {
  final db.User? existing;
  const AddEditUserDialog({super.key, this.existing});

  @override
  ConsumerState<AddEditUserDialog> createState() =>
      _AddEditUserDialogState();
}

class _AddEditUserDialogState extends ConsumerState<AddEditUserDialog> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  String _role = 'pos_clerk';
  Set<String> _permissions = {};
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _role = widget.existing!.role;
      final raw = widget.existing!.permissions;
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            _permissions = decoded.map((e) => e.toString()).toSet();
          }
        } catch (_) {}
      }
    } else {
      _permissions = roleMeta[_role]?.defaultPerms.toSet() ?? {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onRoleChanged(String? newRole) {
    if (newRole == null) return;
    setState(() {
      _role = newRole;
      if (widget.existing == null) {
        _permissions = roleMeta[newRole]?.defaultPerms.toSet() ?? {};
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorText = AppStrings.nameRequired);
      return;
    }
    if (widget.existing == null && (pin.length < 4 || pin.length > 6)) {
      setState(() => _errorText = AppStrings.pinMustBe4To6);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final usersDao = ref.read(usersDaoProvider);
    final activityLogDao = ref.read(authActivityLogDaoProvider);

    try {
      if (widget.existing == null) {
        // Create new user
        final salt = generateSalt();
        final hash = hashPin(pin, salt);
        final permsJson = _permissions.contains('*')
            ? null
            : jsonEncode(_permissions.toList());

        final userId = await usersDao.insertUser(
          db.UsersCompanion(
            name: Value(name),
            pinHash: Value(hash),
            pinSalt: Value(salt),
            role: Value(_role),
            permissions: Value(permsJson),
            isActive: const Value(true),
          ),
        );

        await activityLogDao.insertLog(
          db.ActivityLogCompanion(
            userId: Value(userId),
            action: const Value('add'),
            entityType: const Value('user'),
            entityId: Value(userId),
            details: Value('إضافة موظف: $name'),
          ),
        );
      } else {
        // Update existing user
        final user = widget.existing!;
        String pinHash = user.pinHash;
        String pinSalt = user.pinSalt;

        if (pin.isNotEmpty) {
          pinSalt = generateSalt();
          pinHash = hashPin(pin, pinSalt);
        }

        final permsJson = _permissions.contains('*')
            ? null
            : jsonEncode(_permissions.toList());

        await usersDao.updateUser(user.copyWith(
          name: name,
          role: _role,
          pinHash: pinHash,
          pinSalt: pinSalt,
          permissions: Value(permsJson),
        ));

        await activityLogDao.insertLog(
          db.ActivityLogCompanion(
            userId: Value(user.id),
            action: const Value('edit'),
            entityType: const Value('user'),
            entityId: Value(user.id),
            details: Value('تعديل موظف: $name'),
          ),
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorText = 'خطأ: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEditing ? AppStrings.editUser : AppStrings.addUser,
        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.userName,
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
            ),
            const SizedBox(height: AppSizes.md),

            // PIN field
            TextField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: isEditing
                    ? 'رمز جديد (اتركه فارغ للإبقاء)'
                    : AppStrings.userPin,
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: AppStrings.pinHint,
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Role dropdown
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: AppStrings.userRole,
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              items: roleMeta.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Row(children: [
                    Icon(e.value.icon, size: 18),
                    const SizedBox(width: 8),
                    Text(e.value.label),
                  ]),
                );
              }).toList(),
              onChanged: _onRoleChanged,
            ),
            const SizedBox(height: AppSizes.md),

            // Permissions (hidden for owner — owner has all)
            if (_role != 'owner') ...[
              Text(
                AppStrings.userPermissions,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkLight,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: allPermissionKeys.map((perm) {
                  final isSelected = _permissions.contains(perm);
                  return FilterChip(
                    label: Text(permissionLabelsAr[perm] ?? perm),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _permissions.add(perm);
                        } else {
                          _permissions.remove(perm);
                        }
                      });
                    },
                    selectedColor: AppColors.forest.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.forest,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.forest
                          : AppColors.ledgerBorder,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.md),
            ],

            // Error text
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    color: AppColors.stampRed,
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.background,
                  ),
                )
              : const Text(AppStrings.save2),
        ),
      ],
    );
  }
}