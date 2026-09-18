import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider will control which tab is currently active globally
final dashboardTabProvider = StateProvider<int>((ref) => 0);
