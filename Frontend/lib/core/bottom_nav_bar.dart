import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int customPage;
  const BottomNavBar({super.key, required this.customPage});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discovery'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: customPage,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/discovery-screen');
            break;
          case 1:
            context.go('/matches-screen');
            break;
          case 2:
            context.go('/profile-screen');
            break;
        }
      },
    );
  }
}
