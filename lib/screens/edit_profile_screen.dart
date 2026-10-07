import 'package:ctadmobl_project/models/user_profile.dart';
import 'package:ctadmobl_project/services/auth_service.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _loadFailed = false;
  bool _saveFailed = false;
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _loadFailed = false;
      });
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Sign in to edit your profile.';
        });
      }
      return;
    }
    try {
      final profile = await context
          .read<AuthService>()
          .watchProfile(user.uid)
          .first;
      if (!mounted) return;
      _name.text = profile?.name ?? '';
      _phone.text = profile?.phone ?? '';
      _address.text = profile?.address ?? '';
      _role = profile?.role ?? 'user';
      _error = null;
      _loadFailed = false;
    } catch (error) {
      debugPrint('Unable to load profile for editing: $error');
      _error = appErrorMessage;
      _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Sign in to edit your profile.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _saveFailed = false;
    });
    try {
      await context.read<AuthService>().updateProfile(
        user.uid,
        UserProfile(
          name: _name.text.trim(),
          email: user.email ?? '',
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          role: _role,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      debugPrint('Unable to save profile: $error');
      if (mounted) {
        setState(() {
          _error = appErrorMessage;
          _saveFailed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                if (_loadFailed || _saveFailed)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : _loadFailed
                          ? _loadProfile
                          : _save,
                      child: const Text('Retry'),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (value) =>
                          value == null || value.trim().length < 7
                          ? 'Enter a valid phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your address'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const CircularProgressIndicator()
                            : const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}
