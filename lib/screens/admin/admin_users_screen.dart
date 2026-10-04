import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      // THE FIX: Pointing to the new RPC that bundles budgets and appliances
      final response = await Supabase.instance.client.rpc('get_all_users_admin_data');
      if (mounted && response != null) {
        setState(() {
          _users = List.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching detailed user data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// SECURITY INTERCEPTOR: Forces the admin to re-enter their password before proceeding.
  Future<void> _verifyAdminIdentity(String actionName, VoidCallback onVerified) async {
    final passwordController = TextEditingController();
    bool isVerifying = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final surfaceColor = Theme.of(context).colorScheme.surface;
          final textColor = Theme.of(context).colorScheme.onSurface;

          return AlertDialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.adminRed.withOpacity(0.5)),
            ),
            title: Row(
              children: [
                const Icon(Icons.security, color: AppColors.adminRed),
                const SizedBox(width: 10),
                Text('Security Check', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter your admin password to confirm this $actionName.', style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13)),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: passwordController,
                  hint: 'Admin Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: const TextStyle(color: AppColors.adminRed, fontSize: 12, fontWeight: FontWeight.bold)),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              FilledButton(
                onPressed: isVerifying ? null : () async {
                  setModalState(() {
                    isVerifying = true;
                    errorMessage = null;
                  });
                  try {
                    final currentUser = Supabase.instance.client.auth.currentUser;
                    if (currentUser?.email == null) throw 'Session invalid.';

                    await Supabase.instance.client.auth.signInWithPassword(
                      email: currentUser!.email!,
                      password: passwordController.text,
                    );

                    if (mounted) {
                      Navigator.pop(ctx);
                      onVerified();
                    }
                  } catch (e) {
                    setModalState(() {
                      isVerifying = false;
                      errorMessage = 'Incorrect password. Access denied.';
                    });
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.adminRed, foregroundColor: Colors.white),
                child: isVerifying
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify & Proceed'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditModal(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['full_name']);
    int selectedRole = user['role_id'] ?? 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Edit User', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: nameController, hint: 'Full Name', icon: Icons.person_outline),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: selectedRole,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: [
                DropdownMenuItem(value: 1, child: Text('Standard User', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                const DropdownMenuItem(value: 2, child: Text('Administrator', style: TextStyle(color: AppColors.adminRed))),
              ],
              onChanged: (val) => selectedRole = val!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _verifyAdminIdentity('Edit', () async {
                try {
                  await Supabase.instance.client.rpc('admin_edit_user', params: {
                    'target_user_id': user['id'],
                    'new_name': nameController.text.trim(),
                    'new_role': selectedRole,
                  });
                  _fetchUsers();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully.'), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit failed: $e'), backgroundColor: AppColors.adminRed));
                }
              });
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> user) {
    _verifyAdminIdentity('Deletion', () async {
      try {
        await Supabase.instance.client.rpc('admin_delete_user', params: {
          'target_user_id': user['id']
        });
        _fetchUsers();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User permanently deleted.'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deletion failed: $e'), backgroundColor: AppColors.adminRed));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final filteredUsers = _users.where((u) {
      final search = _searchQuery.toLowerCase();
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(search) || email.contains(search);
    }).toList();

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(),
          title: Text('User Management', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon: Icon(Icons.search, color: hintColor),
                  filled: true,
                  fillColor: surfaceColor.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : filteredUsers.isEmpty
                      ? Center(child: Text('No users found.', style: TextStyle(color: hintColor)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final bool isAdmin = user['role_id'] == 2;
                            final double monthlyBudget = (user['monthly_budget'] as num?)?.toDouble() ?? 0.0;
                            final List appliances = user['appliances'] ?? [];

                            // Calculate cumulative user metrics
                            double totalDailyKwh = 0.0;
                            for (var app in appliances) {
                              final watts = (app['watts'] as num?)?.toDouble() ?? 0.0;
                              final qty = (app['quantity'] as num?)?.toInt() ?? 1;
                              final hours = (app['hours_per_day'] as num?)?.toDouble() ?? 0.0;
                              totalDailyKwh += ((watts * qty) / 1000) * hours;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: surfaceColor.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isAdmin
                                      ? AppColors.adminRed.withOpacity(0.4)
                                      : (isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
                                ),
                              ),
                              child: Theme(
                                // Removes the default border lines from ExpansionTile
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  iconColor: hintColor,
                                  collapsedIconColor: hintColor,
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isAdmin ? AppColors.adminRed.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                                        child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: isAdmin ? AppColors.adminRed : Colors.blueAccent),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(user['full_name'] ?? 'Unknown', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                                            Text(user['email'] ?? 'No Email', style: TextStyle(color: hintColor, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, color: hintColor),
                                        color: surfaceColor,
                                        onSelected: (val) {
                                          if (val == 'edit') _showEditModal(user);
                                          if (val == 'delete') _confirmDelete(user);
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18, color: Colors.blueAccent), const SizedBox(width: 8), Text('Edit Details', style: TextStyle(color: textColor))])),
                                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever, size: 18, color: AppColors.adminRed), SizedBox(width: 8), Text('Delete User', style: TextStyle(color: AppColors.adminRed))])),
                                        ],
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildMetricBadge('Budget Limit', '₱${monthlyBudget.toStringAsFixed(0)}', isDark ? Colors.greenAccent : Colors.green.shade700, isDark, textColor),
                                              _buildMetricBadge('Total Draw', '${totalDailyKwh.toStringAsFixed(1)} kWh/day', AppColors.appYellow, isDark, textColor),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Text('APPLIANCE BREAKDOWN', style: TextStyle(color: hintColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                          const SizedBox(height: 12),
                                          if (appliances.isEmpty)
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                              child: Text('No appliances recorded for this user.', style: TextStyle(color: hintColor, fontSize: 12)),
                                            )
                                          else
                                            ...appliances.map((app) {
                                              final watts = (app['watts'] as num?)?.toDouble() ?? 0.0;
                                              final qty = (app['quantity'] as num?)?.toInt() ?? 1;
                                              final hours = (app['hours_per_day'] as num?)?.toDouble() ?? 0.0;
                                              final kwh = ((watts * qty) / 1000) * hours;

                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 10.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text('${app['name']} (x$qty)', style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                    ),
                                                    Text('${kwh.toStringAsFixed(2)} kWh', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              );
                                            }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge(String label, String value, Color color, bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
