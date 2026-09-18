import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod 3.x Modern Notifier (Replaces the legacy StateProvider)
class DashboardTabNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // Default to the Home tab (Index 0)
  }
}

// The globally accessible provider
final dashboardTabProvider = NotifierProvider<DashboardTabNotifier, int>(
  DashboardTabNotifier.new,
);
