import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/core/services/location_service.dart';
import 'package:tinderclone/features/auth/repository/auth_repository.dart';
import 'package:tinderclone/features/auth/registration/widgets/interest_chip_widget.dart';

class InterestsScreen extends StatefulWidget {
  final UserModel? user;
  const InterestsScreen({super.key, this.user});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final List<String> interests = [
    'Photography',
    'Shopping',
    'Karaoke',
    'Yoga',
    'Cooking',
    'Tennis',
    'Run',
    'Swimming',
    'Art',
    'Traveling',
    'Extreme',
    'Music',
    'Drink',
    'Video games',
  ];

  final Set<String> selected = {};
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 24),
              const Text(
                'Your interests',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a few of your interests and let everyone know what you’re passionate about.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              /// GRID
              Expanded(
                child: GridView.builder(
                  itemCount: interests.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 3.2,
                  ),
                  itemBuilder: (context, index) {
                    final interest = interests[index];
                    final isSelected = selected.contains(interest);

                    return InterestChip(
                      label: interest,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selected.remove(interest);
                          } else {
                            selected.add(interest);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              /// CONTINUE
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0535D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      selected.isEmpty || _isRegistering
                          ? null
                          : _handleContinue,
                  child:
                      _isRegistering
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Continue',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back_ios)),
        TextButton(
          onPressed: () {
            context.go('/discovery-screen');
          },
          child: const Text(
            'Skip',
            style: TextStyle(color: Color(0xFFE0535D), fontSize: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _handleContinue() async {
    final user = widget.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration data is missing.')),
      );
      return;
    }

    setState(() => _isRegistering = true);

    final userWithInterests = user.copyWith(interests: selected.toList());
    final success = await _authRepository.register(userWithInterests);

    if (!mounted) return;

    if (!success) {
      setState(() => _isRegistering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
      return;
    }

    final loginError = await _authRepository.login(
      userWithInterests.email!,
      userWithInterests.passwordHash!,
    );

    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (loginError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loginError)));
      context.go('/login-screen');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id') ?? '';
    if (userId.isNotEmpty) {
      await LocationService().startTracking(userId);
    }

    if (!mounted) return;
    context.go('/discovery-screen');
  }
}
