// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/api_endpoints.dart';

class AppStats {
  final int totalUsers;
  final List<InterestStat> topInterests;
  final List<GenderStat> genderDistribution;
  final List<AgeDistribution> ageDistribution;
  final List<AverageAgeByGender> averageAgeByGender;

  AppStats({
    required this.totalUsers,
    required this.topInterests,
    required this.genderDistribution,
    required this.ageDistribution,
    required this.averageAgeByGender,
  });

  factory AppStats.fromJson(Map<String, dynamic> json) => AppStats(
    totalUsers: json['totalUsers'] as int,
    topInterests:
        (json['topInterests'] as List)
            .map((e) => InterestStat.fromJson(e))
            .toList(),
    genderDistribution:
        (json['genderDistribution'] as List)
            .map((e) => GenderStat.fromJson(e))
            .toList(),
    ageDistribution:
        (json['ageDistribution'] as List)
            .map((e) => AgeDistribution.fromJson(e))
            .toList(),
    averageAgeByGender:
        (json['averageAgeByGender'] as List)
            .map((e) => AverageAgeByGender.fromJson(e))
            .toList(),
  );
}

class InterestStat {
  final String interest;
  final int count;
  InterestStat({required this.interest, required this.count});
  factory InterestStat.fromJson(Map<String, dynamic> j) =>
      InterestStat(interest: j['interest'], count: j['count']);
}

class GenderStat {
  final String gender;
  final int count;
  GenderStat({required this.gender, required this.count});
  factory GenderStat.fromJson(Map<String, dynamic> j) =>
      GenderStat(gender: j['gender'], count: j['count']);
}

class AgeDistribution {
  final String range;
  final int count;
  AgeDistribution({required this.range, required this.count});
  factory AgeDistribution.fromJson(Map<String, dynamic> j) =>
      AgeDistribution(range: j['range'], count: j['count']);
}

class AverageAgeByGender {
  final String gender;
  final double averageAge;
  AverageAgeByGender({required this.gender, required this.averageAge});
  factory AverageAgeByGender.fromJson(Map<String, dynamic> j) =>
      AverageAgeByGender(
        gender: j['gender'],
        averageAge: (j['averageAge'] as num).toDouble(),
      );
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  AppStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse(ApiEndpoints.getStats),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _stats = AppStats.fromJson(data);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Greška ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'App Statistics',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.pink),
            onPressed: _loadStats,
          ),
        ],
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              )
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade300,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadStats,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                      ),
                      child: const Text(
                        'Pokušaj ponovo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadStats,
                color: Colors.pink,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Total Users
                    _buildHeroCard(),
                    const SizedBox(height: 16),

                    // Top Interests
                    _buildSectionCard(
                      title: 'Top Interests',
                      subtitle: '\$unwind + \$group + \$sort',
                      icon: Icons.interests,
                      child: _buildInterestsBars(),
                    ),
                    const SizedBox(height: 16),

                    // Gender + Avg Age
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildSectionCard(
                            title: 'Gender',
                            subtitle: '\$group by Gender',
                            icon: Icons.people,
                            child: _buildGenderBars(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSectionCard(
                            title: 'Avg Age',
                            subtitle: '\$group + \$avg',
                            icon: Icons.cake,
                            child: _buildAvgAge(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Age Distribution
                    _buildSectionCard(
                      title: 'Age Distribution',
                      subtitle: '\$bucket boundaries: [18,25,30,35,40,50]',
                      icon: Icons.bar_chart,
                      child: _buildAgeBars(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }

  //Hero kartica - ukupan broj korisnika

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt, color: Colors.white, size: 48),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Users',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${_stats!.totalUsers}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Wrapper kartica za sekciju

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.pink.shade400),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // Top interesi — horizontalne trake

  Widget _buildInterestsBars() {
    final items = _stats!.topInterests;
    if (items.isEmpty) {
      return const Text(
        'Nema podataka',
        style: TextStyle(color: Colors.black38),
      );
    }
    final maxCount = items.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    final barColors = [
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.teal.shade300,
      Colors.blue.shade300,
      Colors.red.shade300,
      Colors.green.shade300,
      Colors.amber.shade400,
    ];

    return Column(
      children:
          items.asMap().entries.map((entry) {
            final i = entry.key;
            final stat = entry.value;
            final fraction = maxCount > 0 ? stat.count / maxCount : 0.0;
            final color = barColors[i % barColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stat.interest,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${stat.count}',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder:
                        (context, constraints) => Container(
                          width: constraints.maxWidth,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: fraction.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  // Polovi

  Widget _buildGenderBars() {
    final items = _stats!.genderDistribution;
    if (items.isEmpty) {
      return const Text(
        'Nema podataka',
        style: TextStyle(color: Colors.black38),
      );
    }
    final total = items.fold(0, (sum, e) => sum + e.count);
    final genderColors = {
      'Male': Colors.blue.shade300,
      'Female': Colors.pink.shade300,
      'Other': Colors.purple.shade300,
    };

    return Column(
      children:
          items.map((stat) {
            final color = genderColors[stat.gender] ?? Colors.grey.shade300;
            final percent =
                total > 0 ? (stat.count / total * 100).toStringAsFixed(1) : '0';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stat.gender,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  // Prosečne godine po polu

  Widget _buildAvgAge() {
    final items = _stats!.averageAgeByGender;
    if (items.isEmpty) {
      return const Text(
        'Nema podataka',
        style: TextStyle(color: Colors.black38),
      );
    }
    final genderColors = {
      'Male': Colors.blue.shade300,
      'Female': Colors.pink.shade300,
      'Other': Colors.purple.shade300,
    };
    return Column(
      children:
          items.map((stat) {
            final color = genderColors[stat.gender] ?? Colors.grey.shade300;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stat.gender,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '${stat.averageAge}y',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  //Distribucija po godinama ($bucket)

  Widget _buildAgeBars() {
    final items = _stats!.ageDistribution;
    if (items.isEmpty) {
      return const Text(
        'Nema podataka',
        style: TextStyle(color: Colors.black38),
      );
    }
    final maxCount = items.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          items.map((stat) {
            final fraction = maxCount > 0 ? stat.count / maxCount : 0.0;
            final barH = (fraction * 100).clamp(8.0, 100.0);
            return Column(
              children: [
                Text(
                  '${stat.count}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 32,
                  height: barH,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink.shade200, Colors.purple.shade300],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.range,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            );
          }).toList(),
    );
  }
}
