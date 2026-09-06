import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/role_utils.dart';
import 'chat_screen.dart';

/// Simple directory of every other user in the app — reads the same
/// /users collection the drawer/profile screens already use, so no new
/// Firestore rules are needed here. Any signed-in user (student, class
/// rep, or teacher) can see and message any other user; the actual
/// access control enforced is thread *privacy*, via the chats/{chatId}
/// rule (only the two participants can ever read a message).
class ContactPickerScreen extends ConsumerStatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  ConsumerState<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends ConsumerState<ContactPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final myUid = ref.watch(authStateChangesProvider).valueOrNull?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Could not load users: $err')),
              data: (users) {
                final others = users.where((u) => u.uid != myUid).where((u) {
                  if (_query.isEmpty) return true;
                  return u.name.toLowerCase().contains(_query);
                }).toList();

                if (others.isEmpty) {
                  return const Center(child: Text('No matching users.'));
                }

                return ListView.builder(
                  itemCount: others.length,
                  itemBuilder: (context, index) {
                    final user = others[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: RoleUtils.badgeColor(user.role).withOpacity(0.15),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(color: RoleUtils.badgeColor(user.role), fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.role.label),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}