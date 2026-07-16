import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/app_user.dart';

class AppTopBar extends StatelessWidget {
  final String pageTitle;
  final AppUser currentUser;
  final bool isSuperAdminMode;
  final ValueChanged<bool> onRoleChanged;

  const AppTopBar({
    super.key,
    required this.pageTitle,
    required this.currentUser,
    required this.isSuperAdminMode,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              pageTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          SizedBox(
            width: 280,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  tooltip: 'Aramayı temizle',
                  onPressed: () {},
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'User',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Switch(
                  value: isSuperAdminMode,
                  onChanged: onRoleChanged,
                ),
                const Text(
                  'Super Admin',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Bildirimler',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_outlined,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primary,
            child: Text(
              currentUser.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}