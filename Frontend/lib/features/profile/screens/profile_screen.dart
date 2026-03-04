// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/features/profile/repository/users_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UsersRepository _usersRepository = UsersRepository();

  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id') ?? '';

    if (userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final user = await _usersRepository.getUserById(userId);
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) context.go('/login-screen');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'This action is permanent. Your profile, matches and all data will be deleted. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || _user?.id == null) return;

    final success = await _usersRepository.deleteUser(_user!.id!);

    if (!mounted) return;
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) context.go('/login-screen');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete account. Please try again.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _user == null
              ? const Center(
                child: Text(
                  'Unable to load profile.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 20),
                      _buildNameAge(),
                      const SizedBox(height: 8),
                      _buildEmail(),
                      if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSection('About me', _user!.bio!),
                      ],
                      if (_user!.interests != null &&
                          _user!.interests!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildInterests(),
                      ],
                      const SizedBox(height: 24),
                      _buildInfoRow(
                        Icons.person_outline,
                        'Gender',
                        _genderLabel(),
                      ),
                      if (_user!.userPreferences != null) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.favorite_border,
                          'Interested in',
                          _interestedInLabel(),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.cake_outlined,
                          'Age range',
                          '${_user!.userPreferences!.minAgePref}–${_user!.userPreferences!.maxAgePref}',
                        ),
                      ],
                      const SizedBox(height: 40),
                      _buildEditProfileButton(),
                      const SizedBox(height: 12),
                      _buildStatsButton(),
                      const SizedBox(height: 12),
                      _buildLogoutButton(),
                      const SizedBox(height: 12),
                      _buildDeleteAccountButton(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildAvatar() {
    final name = '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.pink.shade300, Colors.pink.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildNameAge() {
    final name =
        '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'.trim().isEmpty
            ? 'Unknown'
            : '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'.trim();
    final age = _user!.age ?? 0;

    return Text(
      '$name, $age',
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildEmail() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          _user!.email ?? '',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _user!.interests!
                    .map(
                      (interest) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.pink.shade200),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.pink.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.pink.shade300),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit_outlined, color: Colors.white),
        label: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade400,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        onPressed: () async {
          await context.push('/edit-profile-screen', extra: _user);
          _loadProfile();
        },
      ),
    );
  }

  Widget _buildStatsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.bar_chart, color: Colors.white),
        label: const Text(
          'App Statistics',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade400,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        onPressed: () => context.push('/stats-screen'),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: const Text(
          'Log out',
          style: TextStyle(color: Colors.redAccent, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _logout,
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
        label: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontSize: 15),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _deleteAccount,
      ),
    );
  }

  String _genderLabel() {
    switch (_user!.gender?.index) {
      case 0:
        return 'Male';
      case 1:
        return 'Female';
      default:
        return 'Other';
    }
  }

  String _interestedInLabel() {
    final pref = _user!.userPreferences;
    if (pref == null) return '—';
    switch (pref.interestedIn.index) {
      case 0:
        return 'Men';
      case 1:
        return 'Women';
      default:
        return 'Everyone';
    }
  }
}
