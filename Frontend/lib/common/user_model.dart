import 'package:tinderclone/common/user_preferences_model.dart';
import 'package:tinderclone/common/user_gender.dart';

class UserModel {
  final String? id;
  final String? email;
  final String? passwordHash;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? bio;
  final List<String>? imageUrls;
  final UserPreferences? userPreferences;
  final UserGender? gender;
  final List<String>? interests;

  UserModel({
    this.id,
    this.email,
    this.passwordHash,
    this.firstName,
    this.lastName,
    this.age,
    this.bio,
    this.imageUrls,
    this.userPreferences,
    this.gender,
    this.interests,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['passwordHash'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      age: json['age'] ?? 0,
      bio: json['bio'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      userPreferences:
          json['userPreferences'] != null
              ? UserPreferences.fromJson(json['userPreferences'])
              : null,
      gender: userGenderFromDynamic(json['gender']),
      interests: List<String>.from(json['interests'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'bio': bio,
      'imageUrls': imageUrls,
      'userPreferences': userPreferences?.toJson(),
      'gender': (gender ?? UserGender.other).index,
      'interests': interests ?? [],
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? passwordHash,
    String? firstName,
    String? lastName,
    int? age,
    String? bio,
    List<String>? imageUrls,
    UserPreferences? userPreferences,
    UserGender? gender,
    List<String>? interests,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      imageUrls: imageUrls ?? this.imageUrls,
      userPreferences: userPreferences ?? this.userPreferences,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
    );
  }
}
