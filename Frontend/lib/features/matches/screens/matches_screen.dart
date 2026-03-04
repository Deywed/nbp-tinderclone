// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/api_endpoints.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/core/repositories/cache_repository.dart';
import 'package:tinderclone/core/services/signalr_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final CacheRepository _cacheRepository = CacheRepository();
  static const Duration _requestTimeout = Duration(seconds: 10);

  List<UserModel> _matches = [];
  bool _isLoading = true;
  String? _currentUserId;
  VoidCallback? _routerListener;

  @override
  void initState() {
    super.initState();
    _loadMatches();

    // Kad match stigne reload listu
    final existing = SignalRService().onMatchReceived;
    SignalRService().onMatchReceived = (matchedUserId) {
      existing?.call(matchedUserId);
      if (mounted) _loadMatches();
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_routerListener == null) {
      final router = GoRouter.of(context);
      _routerListener = () {
        final location = router.routerDelegate.currentConfiguration.uri.path;
        if (location == '/matches-screen' && mounted) {
          _loadMatches();
        }
      };
      router.routerDelegate.addListener(_routerListener!);
    }
  }

  @override
  void dispose() {
    if (_routerListener != null) {
      try {
        GoRouter.of(context).routerDelegate.removeListener(_routerListener!);
      } catch (_) {}
    }
    super.dispose();
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadMatches() async {
    if (_isLoading && _matches.isNotEmpty) return;
    if (mounted) setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('current_user_id') ?? '';

    if (_currentUserId!.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse(ApiEndpoints.getMatches(_currentUserId!));
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> body = jsonDecode(response.body);
        setState(() {
          _matches =
              body
                  .whereType<Map<String, dynamic>>()
                  .map(UserModel.fromJson)
                  .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: Colors.pink.shade400, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Matches',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _matches.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 72,
                      color: Colors.pink.shade200,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No matches yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start swiping to find your match!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadMatches,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap:
                          () => context.push(
                            '/user-profile-screen',
                            extra: _matches[index],
                          ),
                      child: _MatchCard(
                        user: _matches[index],
                        cacheRepository: _cacheRepository,
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final UserModel user;
  final CacheRepository cacheRepository;

  const _MatchCard({required this.user, required this.cacheRepository});

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty
            ? 'Unknown'
            : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final age = user.age ?? 18;
    final initial = fullName[0].toUpperCase();

    final colors = [
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.teal.shade300,
      Colors.blue.shade300,
      Colors.red.shade300,
    ];
    final color = colors[initial.codeUnitAt(0) % colors.length];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // inicijali
          Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
          ),

          // Online indikator
          if (user.id != null && user.id!.isNotEmpty)
            Positioned(
              top: 12,
              right: 12,
              child: FutureBuilder<bool>(
                future: cacheRepository.isUserOnline(user.id!),
                builder: (context, snapshot) {
                  final isOnline = snapshot.data == true;
                  return Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color:
                          isOnline
                              ? Colors.greenAccent.shade400
                              : Colors.white38,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow:
                          isOnline
                              ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.6),
                                  blurRadius: 6,
                                ),
                              ]
                              : null,
                    ),
                  );
                },
              ),
            ),

          // Ime i godine dole
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$fullName, $age',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 12, color: Colors.pink.shade400),
                  const SizedBox(width: 3),
                  Text(
                    'Match',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
