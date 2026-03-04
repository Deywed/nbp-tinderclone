import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/core/services/location_service.dart';
import 'package:tinderclone/features/auth/repository/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome Back!",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Login to continue",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              TextField(
                autocorrect: false,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                autocorrect: false,
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            setState(() => _isLoading = true);
                            final String? errorMessage = await _authRepository
                                .login(
                                  emailController.text.trim(),
                                  passwordController.text,
                                );

                            if (!mounted) return;

                            setState(() => _isLoading = false);

                            if (errorMessage == null) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final userId =
                                  prefs.getString('current_user_id') ?? '';
                              if (userId.isNotEmpty) {
                                await LocationService().startTracking(userId);
                              }

                              if (!mounted) return;
                              context.go('/discovery-screen');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.pink,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "Login",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                ),
              ),

              // ElevatedButton(
              //   onPressed: () async {
              //     try {
              //       // 1. Prvo proveri dozvole (ovo je ključno!)
              //       LocationPermission permission =
              //           await Geolocator.checkPermission();
              //       if (permission == LocationPermission.denied) {
              //         permission = await Geolocator.requestPermission();
              //       }

              //       if (permission == LocationPermission.always ||
              //           permission == LocationPermission.whileInUse) {
              //         print('Fetching discovery feed...');
              //         final users = await _swipeRepository.getDiscoveryFeed();
              //         print('Received ${users.length} users');
              //       } else {
              //         print('Location permission denied by user');
              //       }
              //     } catch (e) {
              //       print('Error: $e');
              //     }
              //   },
              //   child: const Text('Test Discovery Feed'),
              // ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      context.go('/registration-screen');
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
