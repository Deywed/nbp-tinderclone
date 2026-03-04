enum UserGender { male, female, other }

UserGender userGenderFromDynamic(dynamic value) {
  if (value is int) {
    switch (value) {
      case 0:
        return UserGender.male;
      case 1:
        return UserGender.female;
      default:
        return UserGender.other;
    }
  }

  if (value is String) {
    switch (value.toLowerCase()) {
      case 'male':
        return UserGender.male;
      case 'female':
        return UserGender.female;
      default:
        return UserGender.other;
    }
  }

  return UserGender.other;
}

String userGenderToString(UserGender gender) {
  return gender.toString().split('.').last;
}
