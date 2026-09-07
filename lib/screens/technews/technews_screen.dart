// lib/screens/technews/technews_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tech_news_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/department_utils.dart';
import '../../utils/role_utils.dart';
import '../../widgets/tech_news_card.dart';
import 'add_tech_news_screen.dart';

/// Readable by every role, auto-filtered to the viewer's own department
/// via a dropdown they can also switch away from ("All Departments" or
/// any other branch). Only Teacher/Admin sees the "Post" FAB — matches
/// the existing tech_news Firestore rule (isTeacher()-gated writes).
class TechNewsScreen extends ConsumerStatefulWidget {
  const TechNewsScreen({super.key});

  @override
  ConsumerState<TechNewsScreen> createState() => _TechNewsScreenState();
}

class _TechNewsScreenState extends ConsumerState<TechNewsScreen> {
  String? _selectedDepartment; // null/'' = All Departments
  bool _initializedFromProfile = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = profileAsync.valueOrNull;

    // Default the filter to the viewer's own department the first time
    // their profile loads, but let them freely change it afterwards.
    if (!_initializedFromProfile && user != null) {
      _initializedFromProfile = true;
      _selectedDepartment = user.department.isNotEmpty ? user.department : null;
    }

    final canPost = user != null && RoleUtils.isTeacher(user.role);
    final newsAsync = ref.watch(techNewsStreamProvider(_selectedDepartment ?? ''));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<String?>(
              initialValue: _selectedDepartment,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All Departments')),
                ...DepartmentUtils.all.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d))),
              ],
              onChanged: (value) => setState(() => _selectedDepartment = value),
            ),
          ),
          Expanded(
            child: newsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Could not load tech news: $err')),
              data: (newsList) {
                if (newsList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No tech news posted for this department yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: newsList.length,
                  itemBuilder: (context, index) => TechNewsCard(news: newsList[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Post', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTechNewsScreen()),
              ),
            )
          : null,
    );
  }
}