import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  final String uid;
  final String phone;

  const CompleteProfileScreen({
    super.key,
    required this.uid,
    required this.phone,
  });

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _teacherCodeController = TextEditingController();

  UserRole _selectedRole = UserRole.student;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _teacherCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final authService = ref.read(authServiceProvider);

    try {
      if (_selectedRole == UserRole.teacher) {
        final isValid = await authService.validateTeacherCode(
          _teacherCodeController.text.trim(),
        );
        if (!isValid) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid admin access code')),
          );
          return;
        }
      }

      await authService.createUserProfile(
        uid: widget.uid,
        phone: widget.phone,
        name: _nameController.text.trim(),
        role: _selectedRole,
      );
      // No navigation needed — userProfileProvider stream updates
      // automatically and AuthGate will swap to the home screen.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 20),
                Text('I am a...', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...UserRole.values.map(
                  (role) => RadioListTile<UserRole>(
                    value: role,
                    groupValue: _selectedRole,
                    title: Text(role.label),
                    activeColor: const Color(0xFF2E6FF2),
                    onChanged: (value) => setState(() => _selectedRole = value!),
                  ),
                ),
                if (_selectedRole == UserRole.teacher) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _teacherCodeController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Admin access code',
                      helperText: 'Provided by the department administrator',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_selectedRole == UserRole.teacher &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Admin access code is required';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E6FF2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}