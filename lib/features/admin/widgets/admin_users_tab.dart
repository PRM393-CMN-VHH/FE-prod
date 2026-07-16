import 'package:flutter/material.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';
import 'package:prm393/features/auth/models/user.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _searchController = TextEditingController();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    return ApiService().getAdminUsers(search: _searchController.text.trim());
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _toggle(UserModel user) async {
    try {
      if (user.isActive) {
        await ApiService().deactivateAdminUser(int.parse(user.id));
      } else {
        await ApiService().activateAdminUser(int.parse(user.id));
      }
      _refresh();
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }

  Future<void> _updateRole(UserModel user, int roleId) async {
    try {
      await ApiService().updateAdminUserRole(
        userId: int.parse(user.id),
        roleId: roleId,
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: AdminCard(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Tìm user",
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _refresh(),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AdminLoading();
              }
              if (snapshot.hasError) {
                return AdminErrorState(error: snapshot.error!);
              }
              final users =
                  ((snapshot.data!['users'] ??
                              snapshot.data!['userList'] ??
                              snapshot.data!['content'] ??
                              [])
                          as List)
                      .map(
                        (json) =>
                            UserModel.fromJson(json as Map<String, dynamic>),
                      )
                      .toList();
              if (users.isEmpty) {
                return const AdminEmptyState(text: "Không có user");
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final user = users[index];
                  return AdminCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                (user.name.isNotEmpty ? user.name : user.email)
                                    .characters
                                    .first
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.isEmpty ? user.email : user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    user.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: user.isActive,
                              onChanged: (_) => _toggle(user),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            AdminStatusChip(
                              label: user.isActive ? "Đang hoạt động" : "Khóa",
                              color: user.isActive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue:
                                    user.roleId ?? (user.isAdmin ? 1 : 2),
                                decoration: const InputDecoration(
                                  labelText: "Role",
                                  prefixIcon: Icon(Icons.security_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text("Admin"),
                                  ),
                                  DropdownMenuItem(
                                    value: 2,
                                    child: Text("User"),
                                  ),
                                ],
                                onChanged: (roleId) {
                                  if (roleId != null && roleId != user.roleId) {
                                    _updateRole(user, roleId);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
