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
  List<Map<String, dynamic>> _users = [];
  Map<String, List<dynamic>> _userInventories = {};
  Map<String, List<dynamic>> _userPeriods = {};

  @override
  void initState() {
    super.initState();
    _fetchUsersData();
  }

  Future<void> _fetchUsersData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch profiles (for display names)
      final profilesResponse = await supabase
          .from('profiles')
          .select('id, full_name, created_at')
          .order('created_at', ascending: false);

      // 2. Fetch ALL inventory from the appliances table
      final allInventory = await supabase
          .from('appliances')
          .select('user_id, name, watts, hours_per_day, quantity');

      // 3. Fetch ALL recorded billing periods
      final allPeriods = await supabase
          .from('recording_periods')
          .select('user_id, period_name, billing_rate')
          .order('start_date', ascending: false);

      // --- THE FIX: Universal UUID Harvesting ---
      Map<String, List<dynamic>> inventories = {};
      Set<String> allUniqueUserIds = {}; 

      // Harvest from Appliances
      for (var item in allInventory) {
        final String uid = item['user_id'].toString(); // Strict cast
        allUniqueUserIds.add(uid);
        if (!inventories.containsKey(uid)) inventories[uid] = [];
        inventories[uid]!.add(item);
      }

      // Harvest from Billing Periods
      Map<String, List<dynamic>> periods = {};
      for (var item in allPeriods) {
        final String uid = item['user_id'].toString(); // Strict cast
        allUniqueUserIds.add(uid);
        if (!periods.containsKey(uid)) periods[uid] = [];
        periods[uid]!.add(item);
      }

      // Harvest from Profiles
      Map<String, Map<String, dynamic>> profilesMap = {};
      for (var p in profilesResponse) {
        final String uid = p['id'].toString(); // Strict cast
        profilesMap[uid] = p;
        allUniqueUserIds.add(uid); 
      }

      // Build the final unified list of users
      List<Map<String, dynamic>> unifiedUsers = [];
      for (String uid in allUniqueUserIds) {
        final profile = profilesMap[uid];
        
        // Hide other Admin accounts from the user oversight list if desired
        if (profile != null && profile['role_id'] == 2) continue;

        unifiedUsers.add({
          'id': uid,
          'full_name': profile != null ? profile['full_name'] : 'Unknown User (No Profile)',
        });
      }

      // Alphabetical sorting for easy oversight
      unifiedUsers.sort((a, b) => (a['full_name'] ?? '').compareTo(b['full_name'] ?? ''));

      if (mounted) {
        setState(() {
          _users = unifiedUsers;
          _userInventories = inventories;
          _userPeriods = periods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading users: $e'), 
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
                      final String uid = user['id']; // Now guaranteed to be a string
                      final items = _userInventories[uid] ?? [];
                      final periods = _userPeriods[uid] ?? [];

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
                          title: Text(user['full_name'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text('Appliances: ${items.length} | Logs: ${periods.length}', style: TextStyle(color: hintColor, fontSize: 13)),
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