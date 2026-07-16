import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/permission.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  static const List<String> _availableDepartments = [
    'Sensor',
    'Signal',
    'Acoustic',
    'Sonar',
    'Test',
  ];

  final TextEditingController _userSearchController =
      TextEditingController();

  final List<AppUser> _users = [
    AppUser(
      id: 'user-1',
      name: 'Mehmet Kaya',
      email: 'mehmet.kaya@company.com',
      role: UserRole.user,
      departments: const {
        'Sensor',
        'Signal',
      },
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
        Permission.dataExport,
      },
      isActive: true,
      lastLoginAt: DateTime(2026, 7, 15, 8, 45),
      lastLogoutAt: DateTime(2026, 7, 14, 17, 20),
    ),
    AppUser(
      id: 'user-2',
      name: 'Zeynep Demir',
      email: 'zeynep.demir@company.com',
      role: UserRole.user,
      departments: const {
        'Acoustic',
      },
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
        Permission.dataCreate,
        Permission.dataUpdate,
      },
      isActive: true,
      lastLoginAt: DateTime(2026, 7, 15, 9, 10),
      lastLogoutAt: DateTime(2026, 7, 14, 18, 5),
    ),
    AppUser(
      id: 'user-3',
      name: 'Ahmet Yıldız',
      email: 'ahmet.yildiz@company.com',
      role: UserRole.user,
      departments: const {
        'Signal',
      },
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
      },
      isActive: false,
      lastLoginAt: DateTime(2026, 7, 8, 10, 30),
      lastLogoutAt: DateTime(2026, 7, 8, 16, 55),
    ),
    const AppUser(
      id: 'user-4',
      name: 'Elif Arslan',
      email: 'elif.arslan@company.com',
      role: UserRole.user,
      departments: {
        'Sensor',
        'Acoustic',
      },
      permissions: {
        Permission.databaseView,
        Permission.dataView,
        Permission.dataExport,
      },
      isActive: true,
      mustChangePassword: true,
    ),
    AppUser(
      id: 'user-5',
      name: 'Burak Çetin',
      email: 'burak.cetin@company.com',
      role: UserRole.user,
      departments: const {
        'Sonar',
      },
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
      },
      isActive: false,
      isDeleted: true,
      deletedAt: DateTime(2026, 7, 13, 15, 30),
      deletedBy: 'super-admin-1',
    ),
  ];

  String? _selectedUserId;

  final Set<String> _selectedDepartments = {};
  final Set<Permission> _selectedPermissions = {};

  bool _hasUnsavedChanges = false;

  List<AppUser> get _availableUsers {
    return _users.where((user) => !user.isDeleted).toList();
  }

  AppUser? get _selectedUser {
    final selectedUserId = _selectedUserId;

    if (selectedUserId == null) {
      return null;
    }

    for (final user in _users) {
      if (user.id == selectedUserId && !user.isDeleted) {
        return user;
      }
    }

    return null;
  }

  List<AppUser> get _filteredUsers {
    final query = _userSearchController.text.trim().toLowerCase();

    final users = _availableUsers;

    if (query.isEmpty) {
      return users;
    }

    return users.where((user) {
      final matchesName = user.name.toLowerCase().contains(query);

      final matchesEmail = user.email.toLowerCase().contains(query);

      final matchesDepartment = user.departments.any(
        (department) => department.toLowerCase().contains(query),
      );

      return matchesName || matchesEmail || matchesDepartment;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    final users = _availableUsers;

    if (users.isNotEmpty) {
      final firstUser = users.first;

      _selectedUserId = firstUser.id;
      _selectedDepartments.addAll(firstUser.departments);
      _selectedPermissions.addAll(firstUser.permissions);
    }
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  void _selectUser(String userId) {
    final user = _users.firstWhere(
      (item) => item.id == userId && !item.isDeleted,
    );

    setState(() {
      _selectedUserId = user.id;

      _selectedDepartments
        ..clear()
        ..addAll(user.departments);

      _selectedPermissions
        ..clear()
        ..addAll(user.permissions);

      _hasUnsavedChanges = false;
    });
  }

  void _toggleDepartment(
    String department,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        _selectedDepartments.add(department);
      } else {
        _selectedDepartments.remove(department);
      }

      _hasUnsavedChanges = true;
    });
  }

  void _togglePermission(
    Permission permission,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        _selectedPermissions.add(permission);
      } else {
        _selectedPermissions.remove(permission);
      }

      _hasUnsavedChanges = true;
    });
  }

  void _selectAllDepartments() {
    setState(() {
      _selectedDepartments
        ..clear()
        ..addAll(_availableDepartments);

      _hasUnsavedChanges = true;
    });
  }

  void _clearAllDepartments() {
    setState(() {
      _selectedDepartments.clear();
      _hasUnsavedChanges = true;
    });
  }

  void _selectAllPermissions() {
    setState(() {
      _selectedPermissions
        ..clear()
        ..addAll(Permission.values);

      _hasUnsavedChanges = true;
    });
  }

  void _clearAllPermissions() {
    setState(() {
      _selectedPermissions.clear();
      _hasUnsavedChanges = true;
    });
  }

  void _saveChanges() {
    final selectedUser = _selectedUser;

    if (selectedUser == null) {
      return;
    }

    final index = _users.indexWhere(
      (user) => user.id == selectedUser.id,
    );

    if (index == -1) {
      return;
    }

    setState(() {
      _users[index] = selectedUser.copyWith(
        departments: Set<String>.from(
          _selectedDepartments,
        ),
        permissions: Set<Permission>.from(
          _selectedPermissions,
        ),
      );

      _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selectedUser.name} için yetkiler kaydedildi.',
        ),
      ),
    );
  }

  void _cancelChanges() {
    final selectedUser = _selectedUser;

    if (selectedUser == null) {
      return;
    }

    _selectUser(selectedUser.id);
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = _selectedUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 950;

              if (isNarrow) {
                return Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: _buildUserListPanel(),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: selectedUser == null
                          ? _buildNoUserSelected()
                          : _buildPermissionEditor(selectedUser),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: _buildUserListPanel(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: selectedUser == null
                        ? _buildNoUserSelected()
                        : _buildPermissionEditor(selectedUser),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yetki Yönetimi',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Kullanıcıların departman erişimlerini ve işlem yetkilerini belirleyin.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildUserListPanel() {
    final filteredUsers = _filteredUsers;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _userSearchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Kullanıcı ara...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              12,
            ),
            child: Row(
              children: [
                Text(
                  '${filteredUsers.length} kullanıcı',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_availableUsers.where((user) => user.isActive).length} aktif',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Kullanıcı bulunamadı',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 6);
                      },
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];

                        return _buildUserListItem(user);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(AppUser user) {
    final isSelected = user.id == _selectedUserId;

    return Material(
      color: isSelected
          ? AppColors.primary.withOpacity(0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (_hasUnsavedChanges) {
            _showUserChangeConfirmation(user.id);
            return;
          }

          _selectUser(user.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.background,
                child: Text(
                  user.initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (user.departments.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        user.departments.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: user.isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionEditor(AppUser selectedUser) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSelectedUserSummary(selectedUser),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 850;

              if (isNarrow) {
                return Column(
                  children: [
                    _buildDepartmentSection(),
                    const SizedBox(height: 20),
                    _buildPermissionSection(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDepartmentSection(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _buildPermissionSection(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSaveArea(),
        ],
      ),
    );
  }

  Widget _buildSelectedUserSummary(AppUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.10),
            child: Text(
              user.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(
            isActive: user.isActive,
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Text(
              '${_selectedDepartments.length} departman · '
              '${_selectedPermissions.length} yetki',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.apartment_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Departman Erişimleri',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Departman seçenekleri',
                onSelected: (value) {
                  if (value == 'all') {
                    _selectAllDepartments();
                  }

                  if (value == 'clear') {
                    _clearAllDepartments();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'all',
                      child: Text('Tümünü seç'),
                    ),
                    PopupMenuItem<String>(
                      value: 'clear',
                      child: Text('Temizle'),
                    ),
                  ];
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kullanıcının erişebileceği departmanları seçin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          ..._availableDepartments.map((department) {
            final isSelected = _selectedDepartments.contains(
              department,
            );

            return CheckboxListTile(
              value: isSelected,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                department,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '$department departmanındaki verilere erişim',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              onChanged: (value) {
                _toggleDepartment(
                  department,
                  value ?? false,
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPermissionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'İşlem Yetkileri',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: _selectAllPermissions,
                child: const Text('Tümünü seç'),
              ),
              TextButton(
                onPressed: _clearAllPermissions,
                child: const Text('Temizle'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kullanıcının sistemde yapabileceği işlemleri belirleyin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildPermissionGroup(
            title: 'Database İşlemleri',
            icon: Icons.storage_outlined,
            permissions: const [
              Permission.databaseView,
              Permission.databaseCreate,
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 18),
          _buildPermissionGroup(
            title: 'Veri İşlemleri',
            icon: Icons.table_chart_outlined,
            permissions: const [
              Permission.dataView,
              Permission.dataCreate,
              Permission.dataUpdate,
              Permission.dataDelete,
              Permission.dataExport,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionGroup({
    required String title,
    required IconData icon,
    required List<Permission> permissions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...permissions.map((permission) {
          final isSelected = _selectedPermissions.contains(
            permission,
          );

          return CheckboxListTile(
            value: isSelected,
            contentPadding: const EdgeInsets.only(left: 4),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              permission.label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _permissionDescription(permission),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            onChanged: (value) {
              _togglePermission(
                permission,
                value ?? false,
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildSaveArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_hasUnsavedChanges)
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 17,
                  color: AppColors.warning,
                ),
                SizedBox(width: 6),
                Text(
                  'Kaydedilmemiş değişiklikler var',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        OutlinedButton(
          onPressed: _hasUnsavedChanges
              ? _cancelChanges
              : null,
          child: const Text('Değişiklikleri İptal Et'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _hasUnsavedChanges
              ? _saveChanges
              : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Yetkileri Kaydet'),
        ),
      ],
    );
  }

  Widget _buildNoUserSelected() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'Bir kullanıcı seçin',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Departman ve yetki ayarlarını görmek için soldaki listeden kullanıcı seçin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUserChangeConfirmation(
    String newUserId,
  ) async {
    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Kaydedilmemiş değişiklikler',
          ),
          content: const Text(
            'Başka bir kullanıcıya geçerseniz yaptığınız değişiklikler kaybolacak.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Değişiklikleri Sil'),
            ),
          ],
        );
      },
    );

    if (shouldChange == true) {
      _selectUser(newUserId);
    }
  }

  String _permissionDescription(
    Permission permission,
  ) {
    switch (permission) {
      case Permission.databaseView:
        return 'Kullanıcı erişebildiği database yapılarını görüntüleyebilir.';

      case Permission.databaseCreate:
        return 'Kullanıcı yeni database oluşturabilir.';

      case Permission.dataView:
        return 'Kullanıcı kayıtları ve veri tablolarını görüntüleyebilir.';

      case Permission.dataCreate:
        return 'Kullanıcı yeni kayıt veya veri ekleyebilir.';

      case Permission.dataUpdate:
        return 'Kullanıcı mevcut kayıtları değiştirebilir.';

      case Permission.dataDelete:
        return 'Kullanıcı kayıtları silebilir. Database tamamen silinemez.';

      case Permission.dataExport:
        return 'Kullanıcı verileri CSV, JSON veya Excel olarak dışa aktarabilir.';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.success
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Pasif',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}