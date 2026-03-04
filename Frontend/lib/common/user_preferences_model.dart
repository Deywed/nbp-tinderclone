import 'package:tinderclone/common/user_gender.dart';

class UserPreferences {
  final int minAgePref;
  final int maxAgePref;
  final UserGender interestedIn;

  UserPreferences({
    required this.minAgePref,
    required this.maxAgePref,
    required this.interestedIn,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      minAgePref: json['minAgePref'],
      maxAgePref: json['maxAgePref'],
      interestedIn: userGenderFromDynamic(json['interestedIn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minAgePref': minAgePref,
      'maxAgePref': maxAgePref,
      'interestedIn': interestedIn.index,
    };
  }
}
