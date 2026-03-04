// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/core/repositories/cache_repository.dart';
import 'package:tinderclone/core/services/signalr_service.dart';
import 'package:tinderclone/features/discovery/repository/discovery_repository.dart';
import 'package:tinderclone/features/discovery/repository/swipe_repository.dart';
import 'package:tinderclone/features/profile/repository/users_repository.dart';

class DiscoveryScreen extends StatefulWidget {
  final String? currentUserId;

  const DiscoveryScreen({super.key, this.currentUserId});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final SwipeRepository _swipeRepository = SwipeRepository();
  final DiscoveryRepository _discoveryRepository = DiscoveryRepository();
  final CacheRepository _cacheRepository = CacheRepository();
  final UsersRepository _usersRepository = UsersRepository();

  List<UserModel> users = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _currentUserName;
  UserModel? _matchedUser;

  Offset cardOffset = Offset.zero;
  double rotation = 0;

  static const swipeThreshold = 120;

  @override
  void initState() {
    super.initState();
    _bootstrapDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade100,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/top-picks-screen'),
            backgroundColor: Colors.amber.shade700,
            icon: const Icon(Icons.star, color: Colors.white),
            label: const Text(
              'Top Picks',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                  ? const Center(child: Text('No users found.'))
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children:
                            users.asMap().entries.map((entry) {
                              final index = entry.key;
                              final user = entry.value;
                              final isTop = index == users.length - 1;

                              return isTop
                                  ? _buildDraggableCard(user)
                                  : _buildCard(user, index: index, scale: 0.95);
                            }).toList(),
                      ),
                      SizedBox(height: 50),
                      _buildActionButtons(),
                    ],
                  ),
        ),
        if (_matchedUser != null)
          _MatchOverlay(
            matchedUser: _matchedUser!,
            currentUserName: _currentUserName ?? 'You',
            onContinue: () => setState(() => _matchedUser = null),
          ),
      ],
    );
  }

  Widget _buildDraggableCard(UserModel user) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          cardOffset += details.delta;
          rotation = cardOffset.dx / 300;
        });
      },
      onPanEnd: (_) {
        if (cardOffset.dx > swipeThreshold) {
          _swipeRight();
        } else if (cardOffset.dx < -swipeThreshold) {
          _swipeLeft();
        } else {
          _resetCard();
        }
      },
      child: Transform.translate(
        offset: cardOffset,
        child: Transform.rotate(
          angle: rotation,
          child: _buildCard(user, index: users.length - 1),
        ),
      ),
    );
  }

  Widget _buildCard(UserModel user, {required int index, double scale = 1}) {
    final color = _cardColor(index);
    final fullName =
        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty
            ? 'Unknown'
            : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final age = user.age ?? 18;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 320,
        height: 440,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16,
              color: Colors.black26,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ime i godine
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '$fullName, $age',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Online indikator
            if (user.id != null && user.id!.isNotEmpty)
              Positioned(
                top: 16,
                right: 16,
                child: FutureBuilder<bool>(
                  future: _cacheRepository.isUserOnline(user.id!),
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data == true;
                    return Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color:
                            isOnline
                                ? Colors.greenAccent.shade400
                                : Colors.grey.shade400,
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
          ],
        ),
      ),
    );
  }

  void _swipeRight() async {
    final swipedUser = users.isNotEmpty ? users.last : null;
    _removeTopCard();

    final currentUserId = _currentUserId;
    final likedUserId = swipedUser?.id;

    if (currentUserId == null || likedUserId == null || likedUserId.isEmpty) {
      return;
    }

    final isMatch = await _swipeRepository.likeUser(currentUserId, likedUserId);
    if (isMatch && swipedUser != null && mounted) {
      setState(() => _matchedUser = swipedUser);
    }
  }

  void _swipeLeft() async {
    final swipedUser = users.isNotEmpty ? users.last : null;
    _removeTopCard();

    final currentUserId = _currentUserId;
    final dislikedUserId = swipedUser?.id;

    if (currentUserId == null ||
        dislikedUserId == null ||
        dislikedUserId.isEmpty) {
      return;
    }

    await _swipeRepository.dislikeUser(currentUserId, dislikedUserId);
  }

  void _resetCard() {
    setState(() {
      cardOffset = Offset.zero;
      rotation = 0;
    });
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dislike
        GestureDetector(
          onTap: _swipeLeft,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.red.shade200, width: 1.5),
            ),
            child: Icon(
              Icons.close_rounded,
              color: Colors.red.shade400,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 40),
        // Like
        GestureDetector(
          onTap: _swipeRight,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.pink.shade200, width: 1.5),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.pink.shade400,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  void _removeTopCard() {
    if (users.isEmpty) return;

    setState(() {
      users.removeLast();
      cardOffset = Offset.zero;
      rotation = 0;
    });
  }

  Future<void> _loadTopPicks() async {
    try {
      if (_currentUserId == null || _currentUserId!.isEmpty) return;

      final topPicks = await _discoveryRepository.getDiscoveryFeed(
        _currentUserId!,
      );
      if (!mounted) return;

      setState(() {
        users = topPicks.reversed.toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        users = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _bootstrapDiscovery() async {
    _currentUserId = widget.currentUserId;

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('current_user_id');
      _currentUserName =
          prefs.getString('current_user_email')?.split('@').first;
    }

    await _loadTopPicks();
    _connectSignalR();
  }

  void _connectSignalR() {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    final signalR = SignalRService();
    signalR.onMatchReceived = (matchedUserId) async {
      final matchedUser = await _usersRepository.getUserById(matchedUserId);
      if (matchedUser != null && mounted) {
        setState(() => _matchedUser = matchedUser);
      }
    };
    signalR.connect(userId);
  }

  Color _cardColor(int index) {
    const palette = [
      Colors.pink,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
    ];

    return palette[index % palette.length];
  }

  @override
  void dispose() {
    SignalRService().disconnect();
    super.dispose();
  }
}

class _MatchOverlay extends StatefulWidget {
  final UserModel matchedUser;
  final String currentUserName;
  final VoidCallback onContinue;

  const _MatchOverlay({
    required this.matchedUser,
    required this.currentUserName,
    required this.onContinue,
  });

  @override
  State<_MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<_MatchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchedName =
        '${widget.matchedUser.firstName ?? ''} ${widget.matchedUser.lastName ?? ''}'
                .trim()
                .isEmpty
            ? 'Unknown'
            : '${widget.matchedUser.firstName ?? ''} ${widget.matchedUser.lastName ?? ''}'
                .trim();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  children: [
                    const Text(
                      "It's a Match!",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You and $matchedName liked each other',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Avatar(
                    initial: widget.currentUserName[0].toUpperCase(),
                    color: Colors.pink,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.pinkAccent,
                      size: 40,
                    ),
                  ),
                  _Avatar(
                    initial:
                        matchedName.isNotEmpty
                            ? matchedName[0].toUpperCase()
                            : '?',
                    color: Colors.deepPurpleAccent,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      widget.currentUserName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 72),
                  SizedBox(
                    width: 100,
                    child: Text(
                      matchedName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Keep Swiping',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final Color color;

  const _Avatar({required this.initial, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.3),
        border: Border.all(color: color, width: 3),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 20)],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
