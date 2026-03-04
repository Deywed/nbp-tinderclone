import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinderclone/common/user_gender.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/common/user_preferences_model.dart';

class OrientationScreen extends StatefulWidget {
  final UserModel? user;
  const OrientationScreen({super.key, this.user});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  int iAmIndex = 0;
  int lookingForIndex = 1;

  int minAge = 18;
  int maxAge = 30;

  final List<String> iAmOptions = ["Man", "Woman", "Other"];
  final List<String> lookingOptions = ["Men", "Women", "Everyone"];

  UserModel get _currentUser => widget.user ?? UserModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "Your preferences",
          style: TextStyle(
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "I am a",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              _buildTinderSelector(
                selectedIndex: iAmIndex,
                labels: iAmOptions,
                onChanged: (index) => setState(() => iAmIndex = index),
              ),

              const SizedBox(height: 40),

              const Text(
                "I'm looking for",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              _buildTinderSelector(
                selectedIndex: lookingForIndex,
                labels: lookingOptions,
                onChanged: (index) => setState(() => lookingForIndex = index),
              ),

              const SizedBox(height: 40),

              const Text(
                "Preferred age range",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _openAgePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$minAge – $maxAge",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 30),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    final updatedUser = _currentUser.copyWith(
                      gender: _mapIAmToGender(iAmIndex),
                      userPreferences: UserPreferences(
                        minAgePref: minAge,
                        maxAgePref: maxAge,
                        interestedIn: _mapLookingForToGender(lookingForIndex),
                      ),
                    );

                    context.go('/interest-screen', extra: updatedUser);
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  UserGender _mapIAmToGender(int index) {
    switch (index) {
      case 0:
        return UserGender.male;
      case 1:
        return UserGender.female;
      default:
        return UserGender.other;
    }
  }

  UserGender _mapLookingForToGender(int index) {
    switch (index) {
      case 0:
        return UserGender.male;
      case 1:
        return UserGender.female;
      default:
        return UserGender.other;
    }
  }

  Widget _buildTinderSelector({
    required int selectedIndex,
    required List<String> labels,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: List.generate(labels.length, (index) {
        final isActive = index == selectedIndex;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isActive ? Colors.pinkAccent : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 16,
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _openAgePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int tempMin = minAge;
        int tempMax = maxAge;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 360,
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Select Age Range",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _agePicker(
                          initial: tempMin,
                          onChanged: (v) => setModalState(() => tempMin = v),
                        ),

                        _agePicker(
                          initial: tempMax,
                          onChanged: (v) => setModalState(() => tempMax = v),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          minAge = tempMin;
                          maxAge = tempMax;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Done",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _agePicker({
    required int initial,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 120,
      child: CupertinoPicker(
        itemExtent: 38,
        scrollController: FixedExtentScrollController(
          initialItem: initial - 18,
        ),
        onSelectedItemChanged: (value) => onChanged(value + 18),
        children: List.generate(
          83,
          (i) => Center(
            child: Text("${i + 18}", style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
}
