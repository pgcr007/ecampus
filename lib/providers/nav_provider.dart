import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nav_item.dart';

/// Tracks which drawer destination is currently shown inside HomeShell.
/// Simple StateProvider — no need for full named routing since Phase 6
/// is just "one shell, swap the body."
final selectedNavItemProvider = StateProvider<NavItem>((ref) => NavItem.home);