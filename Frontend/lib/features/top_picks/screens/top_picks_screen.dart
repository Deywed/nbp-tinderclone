import 'package:flutter/material.dart';
import 'package:tinderclone/common/top_pick_model.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/core/repositories/cache_repository.dart';
import 'package:tinderclone/features/discovery/repository/discovery_repository.dart';

class TopPicksScreen extends StatefulWidget {
  const TopPicksScreen({super.key});

  @override
  State<TopPicksScreen> createState() => _TopPicksScreenState();
}

class _TopPicksScreenState extends State<TopPicksScreen> {
  final DiscoveryRepository _discoveryRepository = DiscoveryRepository();
  final CacheRepository _cacheRepository = CacheRepository();

  List<TopPickModel> _topPicks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopPicks();
  }

  Future<void> _loadTopPicks() async {
    try {
      final picks = await _discoveryRepository.getTopPicks();
      if (!mounted) return;
      setState(() => _topPicks = picks);
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
        title: const Text(
          'Top Picks',
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
              : _topPicks.isEmpty
              ? const Center(
                child: Text(
                  'No top picks yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadTopPicks,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _topPicks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pick = _topPicks[index];
                    return _TopPickCard(
                      user: pick.user,
                      likeCount: pick.likeCount,
                      rank: index + 1,
                      cacheRepository: _cacheRepository,
                    );
                  },
                ),
              ),
    );
  }
}

class _TopPickCard extends StatelessWidget {
  final UserModel user;
  final int rank;
  final int likeCount;
  final CacheRepository cacheRepository;

  const _TopPickCard({
    required this.user,
    required this.rank,
    required this.likeCount,
    required this.cacheRepository,
  });

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty
            ? 'Unknown'
            : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final age = user.age ?? 18;
    final bio = user.bio ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rank badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _rankColor(rank),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Avatar placeholder
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.pink.shade100,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ),
                // Online indikator
                if (user.id != null && user.id!.isNotEmpty)
                  Positioned(
                    bottom: 2,
                    right: 2,
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
                                    : Colors.grey.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$fullName, $age',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: Colors.pink.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likeCount ${likeCount == 1 ? 'like' : 'likes'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.pink.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // zlato
      case 2:
        return const Color(0xFFAAAAAA); // srebro
      case 3:
        return const Color(0xFFCD7F32); // bronza
      default:
        return Colors.pink.shade300;
    }
  }
}
