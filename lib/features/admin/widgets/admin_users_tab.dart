import 'package:flutter/material.dart';
import 'package:prm393/core/constants/app_messages.dart';
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
  int _page = 1;
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
    return ApiService().getAdminUsers(
      search: _searchController.text.trim(),
      pageNo: _page,
    );
  }

  void _refresh({bool resetPage = true}) {
    setState(() {
      if (resetPage) _page = 1;
      _future = _load();
    });
  }

  Future<void> _toggle(UserModel user) async {
    final willDeactivate = user.isActive;
    if (willDeactivate) {
      final confirmed = await confirmAdminAction(
        context,
        title: AppMessage.adminLockUserTitle.text,
        message: AppMessage.adminLockUserMessage.format([
          user.name.isEmpty ? user.email : user.name,
        ]),
        confirmLabel: AppMessage.adminLockConfirm.text,
        destructive: true,
      );
      if (!confirmed) return;
    }

    try {
      if (willDeactivate) {
        await ApiService().deactivateAdminUser(int.parse(user.id));
      } else {
        await ApiService().activateAdminUser(int.parse(user.id));
      }
      if (!mounted) return;
      showAdminMessage(
        context,
        willDeactivate
            ? AppMessage.adminUserLocked.text
            : AppMessage.adminUserUnlocked.text,
      );
      _refresh(resetPage: false);
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          controller: _searchController,
          hintText: "Tìm theo tên hoặc email",
          onSubmitted: _refresh,
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
              final data = snapshot.data!;
              final users =
                  ((data['users'] ?? data['userList'] ?? data['content'] ?? [])
                          as List)
                      .map(
                        (json) =>
                            UserModel.fromJson(json as Map<String, dynamic>),
                      )
                      .toList();
              final totalPage = (data['totalPage'] as num?)?.toInt() ?? 1;

              if (users.isEmpty) {
                return AdminEmptyState(
                  text: AppMessage.adminEmptyUsers.text,
                  icon: Icons.people_outline,
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                                    backgroundColor: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      (user.name.isNotEmpty
                                              ? user.name
                                              : user.email)
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name.isEmpty
                                              ? user.email
                                              : user.name,
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
                                            color:
                                                AppTheme.textSecondaryColor,
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
                                    label: user.isActive
                                        ? "Đang hoạt động"
                                        : "Đã khóa",
                                    color: user.isActive
                                        ? AdminPalette.success
                                        : AdminPalette.danger,
                                  ),
                                  const SizedBox(width: 8),
                                  AdminStatusChip(
                                    label: user.roleId == 1 || user.isAdmin
                                        ? "Admin"
                                        : "User",
                                    color: user.roleId == 1 || user.isAdmin
                                        ? AdminPalette.info
                                        : AdminPalette.neutral,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  AdminPageControl(
                    page: _page,
                    hasMore: _page < totalPage,
                    onPrevious: () {
                      setState(() {
                        _page--;
                        _future = _load();
                      });
                    },
                    onNext: () {
                      setState(() {
                        _page++;
                        _future = _load();
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
