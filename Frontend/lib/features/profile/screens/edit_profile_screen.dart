// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tinderclone/common/user_gender.dart';
import 'package:tinderclone/common/user_model.dart';
import 'package:tinderclone/common/user_preferences_model.dart';
import 'package:tinderclone/features/profile/repository/users_repository.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UsersRepository _usersRepository = UsersRepository();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;

  late UserGender _gender;
  late UserGender _interestedIn;
  late double _minAge;
  late double _maxAge;
  late List<String> _interests;

  bool _isSaving = false;

  static const List<String> _allInterests = [
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

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _firstNameController = TextEditingController(text: u.firstName ?? '');
    _lastNameController = TextEditingController(text: u.lastName ?? '');
    _ageController = TextEditingController(text: u.age?.toString() ?? '');
    _bioController = TextEditingController(text: u.bio ?? '');
    _gender = u.gender ?? UserGender.other;
    _interestedIn = u.userPreferences?.interestedIn ?? UserGender.other;
    _minAge = (u.userPreferences?.minAgePref ?? 18).toDouble();
    _maxAge = (u.userPreferences?.maxAgePref ?? 40).toDouble();
    _interests = List<String>.from(u.interests ?? []);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = widget.user.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? widget.user.age,
      bio: _bioController.text.trim(),
      gender: _gender,
      interests: _interests,
      userPreferences: UserPreferences(
        minAgePref: _minAge.round(),
        maxAgePref: _maxAge.round(),
        interestedIn: _interestedIn,
      ),
    );

    final success = await _usersRepository.updateUser(widget.user.id!, updated);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update profile. Please try again.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_interests.any((i) => i.toLowerCase() == interest.toLowerCase())) {
        _interests.removeWhere(
          (i) => i.toLowerCase() == interest.toLowerCase(),
        );
      } else {
        _interests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child:
                  _isSaving
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.pink.shade400,
                        ),
                      )
                      : Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.pink.shade500,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _sectionHeader('Basic Info'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ageController,
              label: 'Age',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null) return 'Enter a valid age';
                if (n < 18 || n > 99) return 'Must be between 18 and 99';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              maxLines: 3,
              hint: 'Tell others about yourself...',
            ),
            const SizedBox(height: 28),

            _sectionHeader('Gender'),
            const SizedBox(height: 12),
            _buildGenderSelector(
              value: _gender,
              onChanged: (g) => setState(() => _gender = g),
            ),
            const SizedBox(height: 28),

            _sectionHeader('Preferences'),
            const SizedBox(height: 12),
            const Text(
              'Interested in',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildGenderSelector(
              value: _interestedIn,
              onChanged: (g) => setState(() => _interestedIn = g),
            ),
            const SizedBox(height: 20),
            _buildAgeRangeSlider(),
            const SizedBox(height: 28),

            _sectionHeader('Interests'),
            const SizedBox(height: 12),
            _buildInterestSelector(),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.pink.shade400,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.pink.shade300, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildGenderSelector({
    required UserGender value,
    required void Function(UserGender) onChanged,
  }) {
    final options = [
      (UserGender.male, 'Men', Icons.male),
      (UserGender.female, 'Women', Icons.female),
      (UserGender.other, 'Everyone', Icons.people_outline),
    ];

    return Row(
      children:
          options.map((opt) {
            final (gender, label, icon) = opt;
            final selected = value == gender;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(gender),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        selected ? Colors.pink.shade400 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          selected
                              ? Colors.pink.shade400
                              : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        color: selected ? Colors.white : Colors.grey.shade500,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAgeRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Age range',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_minAge.round()} – ${_maxAge.round()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(_minAge, _maxAge),
          min: 18,
          max: 70,
          divisions: 52,
          activeColor: Colors.pink.shade400,
          inactiveColor: Colors.pink.shade100,
          labels: RangeLabels(
            _minAge.round().toString(),
            _maxAge.round().toString(),
          ),
          onChanged: (RangeValues v) {
            if (v.end - v.start < 2) return;
            setState(() {
              _minAge = v.start;
              _maxAge = v.end;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInterestSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          _allInterests.map((interest) {
            final selected = _interests.any(
              (i) => i.toLowerCase() == interest.toLowerCase(),
            );
            return GestureDetector(
              onTap: () => _toggleInterest(interest),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? Colors.pink.shade400 : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color:
                        selected ? Colors.pink.shade400 : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow:
                      selected
                          ? [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
