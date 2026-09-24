import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminOversightData();
  }

  Future<void> _fetchAdminOversightData() async {
    setState(() => _isLoading = true);
    try {
      // Calls the secure Postgres function we created in the SQL Editor
      final response = await Supabase.instance.client.rpc('get_admin_oversight_data');

      if (mounted) {
        setState(() {
          _users = response as List<dynamic>;

          // Optional: Filter out Admin accounts (role_id == 2) from the oversight list
          _users.removeWhere((u) => u['role_id'] == 2);

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading oversight data: $e'),
          backgroundColor: AppColors.adminRed
        ));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(),
          title: Text('User Oversight', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.adminRed))
            : _users.isEmpty
                ? Center(child: Text('No user data found in the system.', style: TextStyle(color: hintColor)))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final items = user['appliances'] as List<dynamic>;
                      final periods = user['periods'] as List<dynamic>;
                      final String email = user['email'] ?? 'No Email Attached';

                      return Card(
                        color: surfaceColor.withOpacity(0.5),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: textColor.withOpacity(0.1))
                        ),
                        child: ExpansionTile(
                          iconColor: AppColors.adminRed,
                          collapsedIconColor: hintColor,
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['full_name'] ?? 'Unknown User', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              // NEW: Email displayed directly under the user's name
                              Text(email, style: const TextStyle(color: AppColors.appYellow, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Appliances: ${items.length} | Logs: ${periods.length}', style: TextStyle(color: hintColor, fontSize: 13)),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- BILLING RATES ---
                                  const Text('RECORDED RATES', style: TextStyle(color: AppColors.adminRed, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  const SizedBox(height: 8),
                                  if (periods.isEmpty)
                                    Text('No rates logged by user.', style: TextStyle(color: hintColor, fontSize: 13))
                                  else
                                    ...periods.map((p) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(p['period_name'], style: TextStyle(color: textColor, fontSize: 13)),
                                          Text('₱${(p['billing_rate'] as num).toStringAsFixed(2)} / kWh', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )),

                                  const SizedBox(height: 20),

                                  // --- APPLIANCE INVENTORY ---
                                  const Text('CLOUD INVENTORY', style: TextStyle(color: AppColors.adminRed, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  const SizedBox(height: 8),
                                  if (items.isEmpty)
                                    Text('No appliances synced.', style: TextStyle(color: hintColor, fontSize: 13))
                                  else
                                    ...items.map((i) {
                                      final watts = i['watts'] ?? 0;
                                      final qty = i['quantity'] ?? 1;
                                      final hours = i['hours_per_day'] ?? 0.0;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.electrical_services, color: AppColors.adminRed, size: 14),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(i['name'] ?? 'Unknown', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                                  Text('${watts}W • Qty: $qty • ${(hours as num).toStringAsFixed(1)} hrs/day', style: TextStyle(color: hintColor, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
