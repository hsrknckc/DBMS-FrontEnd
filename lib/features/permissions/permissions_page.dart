import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/permission.dart';
import '../users/controllers/users_notifier.dart';

class PermissionsPage extends ConsumerStatefulWidget {
  const PermissionsPage({super.key});

  @override
  ConsumerState<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<PermissionsPage> {
  static const List<String> _availableDepartments = [
    'General',
    'Sensor',
    'Signal',
    'Acoustic',
    'Sonar',
    'Test',
  ];

  static const Map<String, List<String>> _departmentCollections = {
    'General': ['general_records'],
    'Sensor': ['sensor_readings', 'sensor_status', 'device_logs'],
    'Signal': ['signal_records', 'signal_analysis'],
    'Acoustic': ['acoustic_logs', 'acoustic_data'],
    'Sonar': ['sonar_ping_logs'],
    'Test': ['test_collection_1', 'test_collection_2'],
  };

  static const List<Permission> _databasePermissions = [
    Permission.databaseView,
    Permission.databaseCreate,
  ];

  static const List<Permission> _dataPermissions = [
    Permission.dataView,
    Permission.dataCreate,
    Permission.dataUpdate,
    Permission.dataDelete,
    Permission.dataExport,
    Permission.dataImport,
  ];

  final TextEditingController _userSearchController = TextEditingController();

  String? _selectedUserId;
  String? _activeDepartmentTab;

  // Departman erişim seti
  final Set<String> _selectedDepartments = {};
  // Koleksiyon erişim seti: departman → koleksiyonlar
  final Map<String, List<String>> _selectedCollections = {};
  // Departman bazlı database yetkileri
  final Map<String, Set<Permission>> _selectedDatabasePermissions = {};
  // Koleksiyon bazlı veri yetkileri
  final Map<String, Set<Permission>> _selectedCollectionPermissions = {};

  bool _hasUnsavedChanges = false;

  List<AppUser> get _users {
    return ref.watch(usersProvider).valueOrNull ?? [];
  }

  List<AppUser> get _availableUsers {
    return _users.where((user) => !user.isDeleted).toList();
  }

  AppUser? get _selectedUser {
    final selectedUserId = _selectedUserId;
    if (selectedUserId == null) return null;
    for (final user in _users) {
      if (user.id == selectedUserId && !user.isDeleted) return user;
    }
    return null;
  }

  List<AppUser> get _filteredUsers {
    final query = _userSearchController.text.trim().toLowerCase();
    final users = _availableUsers;
    if (query.isEmpty) return users;
    return users.where((user) {
      final matchesName = user.name.toLowerCase().contains(query);
      final matchesEmail = user.email.toLowerCase().contains(query);
      final matchesDepartment = user.departments.any(
        (department) => department.toLowerCase().contains(query),
      );
      return matchesName || matchesEmail || matchesDepartment;
    }).toList();
  }

  int get _activeUserCount =>
      _availableUsers.where((user) => user.isActive).length;

  int get _selectedCollectionCount {
    var count = 0;
    for (final collections in _selectedCollections.values) {
      count += collections.length;
    }
    return count;
  }

  int get _selectedDatabasePermissionCount {
    var count = 0;
    for (final permissions in _selectedDatabasePermissions.values) {
      count += permissions.length;
    }
    return count;
  }

  int get _selectedCollectionPermissionCount {
    var count = 0;
    for (final permissions in _selectedCollectionPermissions.values) {
      count += permissions.length;
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  void _loadUser(AppUser user) {
    _selectedUserId = user.id;

    _selectedDepartments
      ..clear()
      ..addAll(user.departments);

    _selectedCollections.clear();
    user.allowedCollections.forEach((key, value) {
      _selectedCollections[key] = List.from(value);
    });

    _selectedDatabasePermissions.clear();
    user.databasePermissions.forEach((dept, perms) {
      _selectedDatabasePermissions[dept] = Set.from(perms);
    });

    _selectedCollectionPermissions.clear();
    user.collectionPermissions.forEach((col, perms) {
      _selectedCollectionPermissions[col] = Set.from(perms);
    });

    _activeDepartmentTab = _selectedDepartments.isNotEmpty
        ? _selectedDepartments.first
        : _availableDepartments.first;

    _hasUnsavedChanges = false;
  }

  void _selectUser(String userId) {
    final user = _users.firstWhere(
      (item) => item.id == userId && !item.isDeleted,
    );
    setState(() => _loadUser(user));
  }

  void _toggleDepartment(String department, bool selected) {
    setState(() {
      if (selected) {
        _selectedDepartments.add(department);
        if (!_selectedCollections.containsKey(department)) {
          _selectedCollections[department] = [];
        }
        if (!_selectedDatabasePermissions.containsKey(department)) {
          _selectedDatabasePermissions[department] = {};
        }
      } else {
        _selectedDepartments.remove(department);
        _selectedCollections.remove(department);
        _selectedDatabasePermissions.remove(department);
        // Koleksiyon yetkilerini de temizle
        final cols = _departmentCollections[department] ?? [];
        for (final col in cols) {
          _selectedCollectionPermissions.remove(col);
        }
      }
      _hasUnsavedChanges = true;
    });
  }

  void _toggleCollection(String department, String collection, bool selected) {
    setState(() {
      if (!_selectedCollections.containsKey(department)) {
        _selectedCollections[department] = [];
      }
      if (selected) {
        _selectedCollections[department]!.add(collection);
        if (!_selectedCollectionPermissions.containsKey(collection)) {
          _selectedCollectionPermissions[collection] = {};
        }
      } else {
        _selectedCollections[department]!.remove(collection);
        _selectedCollectionPermissions.remove(collection);
      }
      _hasUnsavedChanges = true;
    });
  }

  void _toggleDatabasePermission(
    String department,
    Permission permission,
    bool selected,
  ) {
    setState(() {
      _selectedDatabasePermissions[department] ??= {};
      if (selected) {
        _selectedDatabasePermissions[department]!.add(permission);
      } else {
        _selectedDatabasePermissions[department]!.remove(permission);
      }
      _hasUnsavedChanges = true;
    });
  }

  void _toggleCollectionPermission(
    String collection,
    Permission permission,
    bool selected,
  ) {
    setState(() {
      _selectedCollectionPermissions[collection] ??= {};
      if (selected) {
        _selectedCollectionPermissions[collection]!.add(permission);
      } else {
        _selectedCollectionPermissions[collection]!.remove(permission);
      }
      _hasUnsavedChanges = true;
    });
  }

  void _selectAllDepartments() {
    setState(() {
      for (final dept in _availableDepartments) {
        _selectedDepartments.add(dept);
        _selectedCollections[dept] ??= [];
        _selectedDatabasePermissions[dept] ??= {};
      }
      _hasUnsavedChanges = true;
    });
  }

  void _clearAllDepartments() {
    setState(() {
      _selectedDepartments.clear();
      _selectedCollections.clear();
      _selectedDatabasePermissions.clear();
      _selectedCollectionPermissions.clear();
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    final selectedUser = _selectedUser;
    if (selectedUser == null) return;

    // Aslında ref.watch(usersProvider) ile kullanıcıları almalıyız
    final users = ref.read(usersProvider).valueOrNull ?? [];
    final index = users.indexWhere((user) => user.id == selectedUser.id);
    if (index == -1) return;

    // allowedCollections = seçilen koleksiyonlar
    final newAllowedCollections = <String, List<String>>{};
    _selectedCollections.forEach((dept, cols) {
      newAllowedCollections[dept] = List.from(cols);
    });

    final updatedUser = selectedUser.copyWith(
      departments: Set<String>.from(_selectedDepartments),
      allowedCollections: newAllowedCollections,
      databasePermissions: Map<String, Set<Permission>>.fromEntries(
        _selectedDatabasePermissions.entries.map(
          (e) => MapEntry(e.key, Set<Permission>.from(e.value)),
        ),
      ),
      collectionPermissions: Map<String, Set<Permission>>.fromEntries(
        _selectedCollectionPermissions.entries.map(
          (e) => MapEntry(e.key, Set<Permission>.from(e.value)),
        ),
      ),
    );

    try {
      await ref.read(usersProvider.notifier).updateUser(updatedUser);
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedUser.name} için yetkiler kaydedildi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _cancelChanges() {
    final selectedUser = _selectedUser;
    if (selectedUser == null) return;
    _selectUser(selectedUser.id);
  }

  @override
  Widget build(BuildContext context) {
    final users = _availableUsers;

    if (_selectedUserId == null && users.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedUserId != null) return;
        setState(() {
          _loadUser(users.first);
        });
      });
    }

    final selectedUser = _selectedUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 18),
        _buildScopeOverview(),
        const SizedBox(height: 24),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 950;

              if (isNarrow) {
                return Column(
                  children: [
                    SizedBox(height: 300, child: _buildUserListPanel()),
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
                  SizedBox(width: 320, child: _buildUserListPanel()),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yetki Yönetimi',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Kullanıcıların database, koleksiyon ve işlem kapsamlarını yönetin.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.25),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 17, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'Middleware enforcement bekleniyor',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScopeOverview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;
        final tiles = [
          _MetricTile(
            icon: Icons.group_outlined,
            label: 'Kullanıcı',
            value: '${_availableUsers.length}',
            helper: '$_activeUserCount aktif',
            color: AppColors.primary,
          ),
          _MetricTile(
            icon: Icons.apartment_outlined,
            label: 'Database kapsamı',
            value: '${_selectedDepartments.length}',
            helper: 'seçili departman',
            color: AppColors.success,
          ),
          _MetricTile(
            icon: Icons.folder_copy_outlined,
            label: 'Collection kapsamı',
            value: '$_selectedCollectionCount',
            helper: 'erişim verilen',
            color: AppColors.warning,
          ),
          _MetricTile(
            icon: Icons.rule_folder_outlined,
            label: 'İşlem yetkisi',
            value:
                '${_selectedDatabasePermissionCount + _selectedCollectionPermissionCount}',
            helper: 'tanımlı kural',
            color: AppColors.danger,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: tiles
                .map(
                  (tile) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: tile,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              Expanded(child: tiles[i]),
              if (i != tiles.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUserListPanel() {
    final filteredUsers = _filteredUsers;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _userSearchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Kullanıcı ara...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                  '$_activeUserCount aktif',
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 34,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Kullanıcı bulunamadı',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _availableUsers.isEmpty
                                ? 'Middleware bağlantısını veya kullanıcı kayıtlarını kontrol edin.'
                                : 'Arama filtresini değiştirerek tekrar deneyin.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
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
          ? AppColors.primary.withValues(alpha: 0.10)
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
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  Expanded(child: _buildDepartmentSection()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _buildPermissionSection()),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.10),
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
              _StatusBadge(isActive: user.isActive),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(
                icon: Icons.apartment_outlined,
                label: '${_selectedDepartments.length} database',
              ),
              _SummaryPill(
                icon: Icons.folder_outlined,
                label: '$_selectedCollectionCount collection',
              ),
              _SummaryPill(
                icon: Icons.storage_outlined,
                label: '$_selectedDatabasePermissionCount DB izni',
              ),
              _SummaryPill(
                icon: Icons.table_chart_outlined,
                label: '$_selectedCollectionPermissionCount veri izni',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bu ekran scoped permission payloadını hazırlar. Yetkilerin zorunlu kontrolü middleware tarafında yapılacak.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Departman Erişim Paneli ─────────────────────────────────────────────────

  Widget _buildDepartmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment_outlined, color: AppColors.primary),
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
                  if (value == 'all') _selectAllDepartments();
                  if (value == 'clear') _clearAllDepartments();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'all',
                    child: Text('Tümünü seç'),
                  ),
                  PopupMenuItem<String>(value: 'clear', child: Text('Temizle')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kullanıcının erişebileceği departmanları seçin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: _activeDepartmentTab, // ignore: deprecated_member_use
            decoration: const InputDecoration(
              labelText: 'Departman Seçin',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _availableDepartments.map((dept) {
              return DropdownMenuItem(value: dept, child: Text(dept));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _activeDepartmentTab = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          if (_activeDepartmentTab != null) ...[
            CheckboxListTile(
              value: _selectedDepartments.contains(_activeDepartmentTab),
              title: Text(
                '$_activeDepartmentTab Departmanına Erişim Ver',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) =>
                  _toggleDepartment(_activeDepartmentTab!, val ?? false),
            ),
            const Divider(),
            // Koleksiyonlar
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Koleksiyon Erişimleri:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (_selectedDepartments.contains(_activeDepartmentTab)) ...[
                    Tooltip(
                      message: 'Tümünü Seç',
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 18,
                        icon: const Icon(
                          Icons.select_all_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          final allCols =
                              _departmentCollections[_activeDepartmentTab] ??
                              [];
                          setState(() {
                            _selectedCollections[_activeDepartmentTab!] =
                                List.from(allCols);
                            for (final col in allCols) {
                              _selectedCollectionPermissions[col] ??= {};
                            }
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Temizle',
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 18,
                        icon: const Icon(
                          Icons.deselect_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          final allCols =
                              _departmentCollections[_activeDepartmentTab] ??
                              [];
                          setState(() {
                            _selectedCollections[_activeDepartmentTab!] = [];
                            for (final col in allCols) {
                              _selectedCollectionPermissions.remove(col);
                            }
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!_selectedDepartments.contains(_activeDepartmentTab))
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'Koleksiyon seçebilmek için önce departman erişimi verin.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            else
              ...(_departmentCollections[_activeDepartmentTab] ?? []).map((
                col,
              ) {
                final isColSelected =
                    (_selectedCollections[_activeDepartmentTab] ?? []).contains(
                      col,
                    );
                return CheckboxListTile(
                  value: isColSelected,
                  title: Text(col, style: const TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 16),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) => _toggleCollection(
                    _activeDepartmentTab!,
                    col,
                    val ?? false,
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  // ── İşlem Yetkileri Paneli ─────────────────────────────────────────────────

  Widget _buildPermissionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
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
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Her database ve koleksiyon için ayrı ayrı işlem yetkileri belirleyin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),

          if (_activeDepartmentTab == null ||
              !_selectedDepartments.contains(_activeDepartmentTab))
            _buildPermissionsEmptyHint()
          else ...[
            // ── Database İşlemleri ──────────────────────────────────────────
            _buildPermissionsGroupHeader(
              icon: Icons.storage_outlined,
              title: 'Database İşlemleri',
              subtitle: '$_activeDepartmentTab veritabanı için yetkiler',
            ),
            const SizedBox(height: 12),
            _buildDatabasePermissionsCard(_activeDepartmentTab!),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // ── Veri İşlemleri ──────────────────────────────────────────────
            _buildPermissionsGroupHeader(
              icon: Icons.table_chart_outlined,
              title: 'Veri İşlemleri',
              subtitle: 'Her koleksiyon için ayrı yetkiler',
            ),
            const SizedBox(height: 12),
            _buildCollectionPermissionsArea(_activeDepartmentTab!),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionsEmptyHint() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'İzin ayarlamak için sol panelden bir departman seçin ve departman erişimini etkinleştirin.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsGroupHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Seçili departman için database yetkileri (databaseView, databaseCreate)
  Widget _buildDatabasePermissionsCard(String department) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: _databasePermissions.map((permission) {
          final isSelected = (_selectedDatabasePermissions[department] ?? {})
              .contains(permission);
          return CheckboxListTile(
            value: isSelected,
            contentPadding: const EdgeInsets.only(left: 4),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
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
            onChanged: (val) =>
                _toggleDatabasePermission(department, permission, val ?? false),
          );
        }).toList(),
      ),
    );
  }

  /// Seçili departmanın koleksiyonları için veri yetkileri
  Widget _buildCollectionPermissionsArea(String department) {
    final cols = _departmentCollections[department] ?? [];
    final activeCols = (_selectedCollections[department] ?? []);

    if (cols.isEmpty) {
      return const Text(
        'Bu departmana ait koleksiyon bulunamadı.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }

    return Column(
      children: cols.map((col) {
        final isColActive = activeCols.contains(col);
        return _CollectionPermissionCard(
          collectionName: col,
          isCollectionActive: isColActive,
          permissions: _dataPermissions,
          selectedPermissions: _selectedCollectionPermissions[col] ?? {},
          onPermissionChanged: (perm, val) =>
              _toggleCollectionPermission(col, perm, val),
          onCollectionToggle: (val) => _toggleCollection(department, col, val),
        );
      }).toList(),
    );
  }

  Widget _buildSaveArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasUnsavedChanges
              ? AppColors.warning.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.end,
        children: [
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 17, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text(
                    'Kaydedilmemiş scoped permission değişiklikleri var',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: _hasUnsavedChanges ? _cancelChanges : null,
            icon: const Icon(Icons.undo_outlined),
            label: const Text('İptal Et'),
          ),
          ElevatedButton.icon(
            onPressed: _hasUnsavedChanges ? _saveChanges : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Yetkileri Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUserSelected() {
    final hasUsers = _availableUsers.isNotEmpty;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasUsers
                    ? Icons.person_search_outlined
                    : Icons.cloud_off_outlined,
                size: 52,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                hasUsers ? 'Bir kullanıcı seçin' : 'Kullanıcı kaynağı boş',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasUsers
                    ? 'Database ve koleksiyon kapsamını düzenlemek için soldaki listeden kullanıcı seçin.'
                    : 'Middleware bağlantısı aktif değilse veya kullanıcı kayıtları gelmediyse burada düzenleme yapılamaz.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUserChangeConfirmation(String newUserId) async {
    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kaydedilmemiş değişiklikler'),
          content: const Text(
            'Başka bir kullanıcıya geçerseniz yaptığınız değişiklikler kaybolacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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

  String _permissionDescription(Permission permission) {
    switch (permission) {
      case Permission.databaseView:
        return 'Bu database\'in yapısını görüntüleyebilir.';
      case Permission.databaseCreate:
        return 'Bu database\'e yeni koleksiyon ekleyebilir.';
      case Permission.dataView:
        return 'Koleksiyondaki kayıtları görüntüleyebilir.';
      case Permission.dataCreate:
        return 'Koleksiyona yeni kayıt ekleyebilir.';
      case Permission.dataUpdate:
        return 'Koleksiyondaki mevcut kayıtları değiştirebilir.';
      case Permission.dataDelete:
        return 'Koleksiyondaki kayıtları silebilir.';
      case Permission.dataExport:
        return 'Koleksiyondan veri dışa aktarabilir.';
      case Permission.dataImport:
        return 'Koleksiyona veri içe aktarabilir.';
    }
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        helper,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Koleksiyon Yetki Kartı ──────────────────────────────────────────────────

class _CollectionPermissionCard extends StatefulWidget {
  final String collectionName;
  final bool isCollectionActive;
  final List<Permission> permissions;
  final Set<Permission> selectedPermissions;
  final void Function(Permission, bool) onPermissionChanged;
  final void Function(bool) onCollectionToggle;

  const _CollectionPermissionCard({
    required this.collectionName,
    required this.isCollectionActive,
    required this.permissions,
    required this.selectedPermissions,
    required this.onPermissionChanged,
    required this.onCollectionToggle,
  });

  @override
  State<_CollectionPermissionCard> createState() =>
      _CollectionPermissionCardState();
}

class _CollectionPermissionCardState extends State<_CollectionPermissionCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(_CollectionPermissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Koleksiyon yeni işaretlendiğinde yetki listesini otomatik aç
    if (widget.isCollectionActive && !oldWidget.isCollectionActive) {
      setState(() => _expanded = true);
    }
    // Koleksiyon işareti kaldırılınca kapat
    if (!widget.isCollectionActive && oldWidget.isCollectionActive) {
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = widget.selectedPermissions.length;
    final totalCount = widget.permissions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isCollectionActive
              ? AppColors.primary.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          // Koleksiyon başlık satırı
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.isCollectionActive
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 14, 8),
              child: Row(
                children: [
                  // Erişim checkbox
                  Checkbox(
                    value: widget.isCollectionActive,
                    onChanged: (val) => widget.onCollectionToggle(val ?? false),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: widget.isCollectionActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.collectionName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isCollectionActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (widget.isCollectionActive) ...[
                    // Yetki sayısı badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: activeCount > 0
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$activeCount/$totalCount yetki',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: activeCount > 0
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Genişletilmiş yetki listesi
          if (widget.isCollectionActive && _expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: widget.permissions.map((perm) {
                  final isSelected = widget.selectedPermissions.contains(perm);
                  return CheckboxListTile(
                    value: isSelected,
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 8),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      perm.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onChanged: (val) =>
                        widget.onPermissionChanged(perm, val ?? false),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status Badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
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
