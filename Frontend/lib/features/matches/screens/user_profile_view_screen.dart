// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/api_endpoints.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/core/repositories/cache_repository.dart';

class UserProfileViewScreen extends StatefulWidget {
  final UserModel user;

  const UserProfileViewScreen({super.key, required this.user});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  static const Duration _requestTimeout = Duration(seconds: 10);
  bool _isUnmatching = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _currentUserId = prefs.getString('current_user_id'));
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _unmatch() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    final name = widget.user.firstName ?? 'this user';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Unmatch'),
            content: Text('Are you sure you want to unmatch with $name?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Unmatch',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isUnmatching = true);

    try {
      final url = Uri.parse(
        '${ApiEndpoints.removeMatch}?userId=${_currentUserId ?? ''}&matchedUserId=${widget.user.id ?? ''}',
      );
      final response = await http
          .delete(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final firstName = widget.user.firstName ?? 'user';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unmatched with $firstName.'),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to unmatch. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connection error. Please try again.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUnmatching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final fullName =
        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty
            ? 'Unknown'
            : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final age = user.age ?? 0;
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    final colors = [
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.teal.shade300,
      Colors.blue.shade300,
      Colors.red.shade300,
    ];
    final avatarColor = colors[initial.codeUnitAt(0) % colors.length];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: avatarColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [avatarColor.withOpacity(0.7), avatarColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white24,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Online indikator
                        if (user.id != null && user.id!.isNotEmpty)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: FutureBuilder<bool>(
                              future: CacheRepository().isUserOnline(user.id!),
                              builder: (context, snapshot) {
                                final isOnline = snapshot.data == true;
                                return Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color:
                                        isOnline
                                            ? Colors.greenAccent.shade400
                                            : Colors.white38,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow:
                                        isOnline
                                            ? [
                                              BoxShadow(
                                                color: Colors.green.withOpacity(
                                                  0.6,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ]
                                            : null,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$fullName, $age',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sadržaj
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$fullName, $age',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.pink.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 14,
                              color: Colors.pink.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Match',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bio
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionLabel('About'),
                    const SizedBox(height: 6),
                    Text(
                      user.bio!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Interesi
                  if (user.interests != null && user.interests!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Interests'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          user.interests!
                              .map(
                                (i) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.pink.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    i,
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

                  // Unmatch button
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUnmatching ? null : _unmatch,
                      icon:
                          _isUnmatching
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red.shade400,
                                ),
                              )
                              : Icon(
                                Icons.heart_broken_outlined,
                                color: Colors.red.shade400,
                              ),
                      label: Text(
                        'Unmatch',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Info
                  const SizedBox(height: 24),
                  _sectionLabel('Info'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.person_outline, 'Gender', _genderLabel(user)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  String _genderLabel(UserModel u) {
    switch (u.gender?.index) {
      case 0:
        return 'Male';
      case 1:
        return 'Female';
      default:
        return 'Other';
    }
  }
}
