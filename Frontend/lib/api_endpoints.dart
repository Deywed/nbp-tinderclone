class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'http://localhost:5225/api';

  // AuthController
  static const String login = '$baseUrl/Auth/Login';
  static const String register = '$baseUrl/Auth/Register';

  // UsersController
  static const String createUser = '$baseUrl/Users/CreateUser';
  static const String getAllUsers = '$baseUrl/Users/GetAllUsers';
  static String getUser(String id) => '$baseUrl/Users/GetUser/$id';
  static String updateUser(String id) => '$baseUrl/Users/UpdateUser/$id';
  static String deleteUser(String id) => '$baseUrl/Users/DeleteUser/$id';
  static const String getUserByEmail = '$baseUrl/Users/GetUserByEmail';

  // DiscoveryController
  static String getUsersByInterestDiscovery(String interest) =>
      '$baseUrl/Discovery/GetUsersByInterest/$interest';
  static const String getTopPicksDiscovery = '$baseUrl/Discovery/GetTopPicks';
  static String getRecommendations(String userId) =>
      '$baseUrl/Discovery/GetRecommendations/$userId';
  static String getDiscoveryFeed(String userId) =>
      '$baseUrl/Discovery/GetDiscoveryFeed/$userId';
  static String updateLocationDiscovery(String userId) =>
      '$baseUrl/Discovery/update-location/$userId';

  // SwipeController
  static const String likeUser = '$baseUrl/Swipe/Like';
  static const String dislikeUser = '$baseUrl/Swipe/Dislike';
  static String getMatches(String userId) => '$baseUrl/Swipe/Matches/$userId';
  static const String removeMatch = '$baseUrl/Swipe/RemoveMatch';
  static const String blockUser = '$baseUrl/Swipe/Block';

  // CacheController
  static String ping(String userId) => '$baseUrl/Cache/ping/$userId';
  static String onlineStatus(String userId) =>
      '$baseUrl/Cache/online-status/$userId';
  static const String updateLocationCache = '$baseUrl/Cache/UpdateLocation';
  static String getNearbyUsers(String userId, double radiusKm) =>
      '$baseUrl/Cache/NearbyUsers/$userId?radiusKm=$radiusKm';
  static const String matchAlert = '$baseUrl/Cache/MatchAlert';
  static String getUserLocation(String userId) =>
      '$baseUrl/Cache/GetUserLocation/$userId';

  // StatsController
  static const String getStats = '$baseUrl/Stats';
}
