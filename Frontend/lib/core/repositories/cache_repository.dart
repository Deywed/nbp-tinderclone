import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinderclone/api_endpoints.dart';

class UserLocation {
  final String userId;
  final double latitude;
  final double longitude;

  UserLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userId: json['userId']?.toString() ?? '',
      latitude:
          (json['latitude'] as num?)?.toDouble() ??
          (json['Latitude'] as num?)?.toDouble() ??
          0.0,
      longitude:
          (json['longitude'] as num?)?.toDouble() ??
          (json['Longitude'] as num?)?.toDouble() ??
          0.0,
    );
  }
}

class CacheRepository {
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> ping(String userId) async {
    try {
      final url = Uri.parse(ApiEndpoints.ping(userId));
      final response = await http
          .post(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isUserOnline(String userId) async {
    try {
      final url = Uri.parse(ApiEndpoints.onlineStatus(userId));
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['isOnline'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateLocation(String userId, double lat, double lon) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.updateLocationCache}?userId=$userId&lat=$lat&lon=$lon',
      );
      final response = await http
          .post(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> getNearbyUsers(String userId, double radiusKm) async {
    try {
      final url = Uri.parse(ApiEndpoints.getNearbyUsers(userId, radiusKm));
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendMatchAlert(String userId, String matchedWithId) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.matchAlert}?userId=$userId&matchedWithId=$matchedWithId',
      );
      final response = await http
          .post(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<UserLocation?> getUserLocation(String userId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getUserLocation(userId));
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return UserLocation.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
